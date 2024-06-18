# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EVSS::DisabilityCompensationForm::Form4142DocumentUploadFailureEmail, type: :job do
  subject { described_class }

  let!(:form526_submission) { create(:form526_submission) }
  let(:notification_client) { double('Notifications::Client') }
  let(:formatted_submit_date) do
    # We display dates in mailers in the format "May 1, 2024 3:01 p.m. EDT"
    form526_submission.created_at.strftime('%B %-d, %Y %-l:%M %P %Z').sub(/([ap])m/, '\1.m.')
  end

  before do
    Sidekiq::Job.clear_all
    allow(Notifications::Client).to receive(:new).and_return(notification_client)
  end

  describe '#perform' do
    it 'dispatches a failure notification' do
      expect(notification_client).to receive(:send_email).with(
        # Email address and first_name are from our User fixtures
        # form4142_upload_failure_notification_template_id is a placeholder in settings.yml
        {
          email_address: 'test@email.com',
          template_id: 'form4142_upload_failure_notification_template_id',
          personalisation: {
            first_name: 'BEYONCE',
            date_submitted: formatted_submit_date
          }
        }
      )

      subject.perform_async(form526_submission.id)
      subject.drain
    end
  end

  describe 'logging' do
    it 'increments a Statsd metric' do
      allow(notification_client).to receive(:send_email)

      expect do
        subject.perform_async(form526_submission.id)
        subject.drain
      end.to trigger_statsd_increment(
        'api.form_526.veteran_notifications.form4142_upload_failure_email.success'
      )
    end

    it 'creates a Form526JobStatus' do
      allow(notification_client).to receive(:send_email)

      expect do
        subject.perform_async(form526_submission.id)
        subject.drain
      end.to change(Form526JobStatus, :count).by(1)
    end
  end

  context 'when retries are exhausted' do
    let!(:form526_job_status) { create(:form526_job_status, :retryable_error, form526_submission:, job_id: 123) }
    let(:retry_params) do
      {
        'jid' => 123,
        'error_class' => 'JennyNotFound',
        'args' => [form526_submission.id]
      }
    end

    let(:exhaustion_time) { DateTime.new(1985, 10, 26).utc }

    before do
      allow(notification_client).to receive(:send_email)
    end

    it 'increments a StatsD exhaustion metric, logs to the Rails logger and updates the job status' do
      Timecop.freeze(exhaustion_time) do
        described_class.within_sidekiq_retries_exhausted_block(retry_params) do
          expect(Rails.logger).to receive(:warn).with(
            'Form4142DocumentUploadFailureEmail retries exhausted',
            {
              job_id: 123,
              error_class: 'JennyNotFound',
              timestamp: exhaustion_time,
              form526_submission_id: form526_submission.id
            }
          ).and_call_original
          expect(StatsD).to receive(:increment).with(
            'api.form_526.veteran_notifications.form4142_upload_failure_email.exhausted'
          )
        end

        expect(form526_job_status.reload.status).to eq(Form526JobStatus::STATUS[:exhausted])
      end
    end
  end
end