# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EVSS::DisabilityCompensationForm::SubmitForm0781, type: :job do
  subject { described_class }

  before do
    Sidekiq::Job.clear_all
    Flipper.disable(:disability_compensation_use_api_provider_for_0781)
  end

  let(:user) { FactoryBot.create(:user, :loa3) }
  let(:auth_headers) do
    EVSS::DisabilityCompensationAuthHeaders.new(user).add_headers(EVSS::AuthHeaders.new(user).to_h)
  end
  let(:evss_claim_id) { 123_456_789 }
  let(:saved_claim) { FactoryBot.create(:va526ez) }
  # has 0781 and 0781a
  let(:form0781) do
    File.read 'spec/support/disability_compensation_form/submissions/with_0781.json'
  end
  let(:form0781_only) do
    original = JSON.parse(form0781)
    original['form0781'].delete('form0781a')
    original.to_json
  end
  # AJ TODO - can try something like this for generated PDF arg:
  # let(:sample_pdf) { File.read('spec/fixtures/pdf_fill/21-0781/simple.pdf') }

  VCR.configure do |c|
    c.default_cassette_options = {
      match_requests_on: [:method,
                          VCR.request_matchers.uri_without_params(:qqfile, :docType, :docTypeDescription)]
    }
    # the response body may not be encoded according to the encoding specified in the HTTP headers
    # VCR will base64 encode the body of the request or response during serialization,
    # in order to preserve the bytes exactly.
    c.preserve_exact_body_bytes do |http_message|
      http_message.body.encoding.name == 'ASCII-8BIT' ||
        !http_message.body.valid_encoding?
    end
  end

  describe '.perform_async' do
    let(:submission) do
      Form526Submission.create(user_uuid: user.uuid,
                               auth_headers_json: auth_headers.to_json,
                               saved_claim_id: saved_claim.id,
                               form_json: form0781,
                               submitted_claim_id: evss_claim_id)
    end

    context 'with a successful submission job' do
      it 'queues a job for submit' do
        expect do
          subject.perform_async(submission.id)
        end.to change(subject.jobs, :size).by(1)
      end

      it 'submits successfully' do
        VCR.use_cassette('evss/disability_compensation_form/submit_0781') do
          subject.perform_async(submission.id)
          jid = subject.jobs.last['jid']
          described_class.drain
          expect(jid).not_to be_empty
        end
      end
    end

    context 'with a submission timeout' do
      before do
        allow_any_instance_of(Faraday::Connection).to receive(:post).and_raise(Faraday::TimeoutError)
      end

      it 'raises a gateway timeout error' do
        subject.perform_async(submission.id)
        expect { described_class.drain }.to raise_error(StandardError)
      end
    end

    context 'with an unexpected error' do
      before do
        allow_any_instance_of(Faraday::Connection).to receive(:post).and_raise(StandardError.new('foo'))
      end

      it 'raises a standard error' do
        subject.perform_async(submission.id)
        expect { described_class.drain }.to raise_error(StandardError)
      end
    end
  end

  describe 'When an ApiProvider is used for uploads' do
    let(:submission) do
      Form526Submission.create(user_uuid: user.uuid,
                               auth_headers_json: auth_headers.to_json,
                               saved_claim_id: saved_claim.id,
                               form_json: form0781_only,
                               submitted_claim_id: evss_claim_id)
    end
    let(:perform_upload) do
      subject.perform_async(submission.id)
      described_class.drain
    end

    before do
      Flipper.enable(:disability_compensation_use_api_provider_for_0781)
      # StatsD metrics are incremented in several callbacks we're not testing here so we need to allow them
      allow(StatsD).to receive(:increment)
    end

    context 'when the disability_compensation_upload_0781_to_lighthouse flipper is enabled' do
      let(:faraday_response) { instance_double(Faraday::Response) }
      let(:lighthouse_request_id) { Faker::Number.number(digits: 8) }
      let(:expected_statsd_metrics_prefix) do
        'worker.evss.submit_form0781.lighthouse_supplemental_document_upload_provider'
      end
      let(:expected_lighthouse_document) do
        LighthouseDocument.new(
          claim_id: submission.submitted_claim_id,
          participant_id: submission.auth_headers['va_eauth_pid'],
          document_type: 'L228'
        )
      end

      before do
        Flipper.enable(:disability_compensation_lighthouse_upload_0781)

        allow(BenefitsDocuments::Form526::UploadSupplementalDocumentService).to receive(:call)
          .and_return(faraday_response)

        allow(faraday_response).to receive(:body).and_return(
          {
            'data' => {
              'success' => true,
              'requestId' => lighthouse_request_id
            }
          }
        )
      end

      it 'uploads the 0781 documents to Lighthouse' do
        allow_any_instance_of(LighthouseSupplementalDocumentUploadProvider).to receive(:generate_upload_document).and_return(expected_lighthouse_document)
        expect(BenefitsDocuments::Form526::UploadSupplementalDocumentService).to receive(:call)
          .with(
            an_instance_of(String), # generated file
            expected_lighthouse_document
          )

        perform_upload
      end

      it 'logs the upload attempt with the correct job prefix' do
        expect(StatsD).to receive(:increment).with(
          "#{expected_statsd_metrics_prefix}.upload_attempt"
        )
        perform_upload
      end

      it 'increments the correct StatsD success metric' do
        expect(StatsD).to receive(:increment).with(
          "#{expected_statsd_metrics_prefix}.upload_success"
        )

        perform_upload
      end

      it 'creates a pending Lighthouse526DocumentUpload record for the submission so we can poll Lighthouse later' do
        upload_attributes = {
          aasm_state: 'pending',
          form526_submission_id: submission.id,
          lighthouse_document_request_id: lighthouse_request_id
        }

        expect(Lighthouse526DocumentUpload.where(**upload_attributes).count).to eq(0)

        perform_upload
        expect(Lighthouse526DocumentUpload.where(**upload_attributes).where(document_type: 'Form 0781').count).to eq(1)
      end

      context 'when Lighthouse returns an error response' do
        let(:error_response_body) do
          # From vcr_cassettes/lighthouse/benefits_claims/documents/lighthouse_form_526_document_upload_400.yml
          {
            'errors' => [
              {
                'detail' => 'Something broke',
                'status' => 400,
                'title' => 'Bad Request',
                'instance' => Faker::Internet.uuid
              }
            ]
          }
        end

        before do
          allow(BenefitsDocuments::Form526::UploadSupplementalDocumentService).to receive(:call)
            .and_return(faraday_response)

          allow(faraday_response).to receive(:body).and_return(error_response_body)
        end

        it 'logs the Lighthouse error response' do
          expect(Rails.logger).to receive(:error).with(
            'LighthouseSupplementalDocumentUploadProvider upload failed',
            {
              class: 'LighthouseSupplementalDocumentUploadProvider',
              submission_id: submission.submitted_claim_id,
              user_uuid: submission.user_uuid,
              va_document_type_code: 'L228',
              primary_form: 'Form526',
              lighthouse_error_response: error_response_body
            }
          )

          perform_upload
        end

        it 'increments the correct status failure metric' do
          expect(StatsD).to receive(:increment).with(
            "#{expected_statsd_metrics_prefix}.upload_failure"
          )

          perform_upload
        end
      end
    end

    context 'when the disability_compensation_upload_0781_to_lighthouse flipper is disabled' do
      let(:faraday_response) { instance_double(Faraday::Response) }
      let(:expected_statsd_metrics_prefix) do
        'worker.evss.submit_form0781.evss_supplemental_document_upload_provider'
      end
      let(:evss_claim_document) do
        EVSSClaimDocument.new(
          evss_claim_id: submission.submitted_claim_id,
          document_type: 'L228'
        )
      end

      before do
        Flipper.disable(:disability_compensation_lighthouse_upload_0781)
        allow_any_instance_of(EVSS::DocumentsService).to receive(:upload)
      end

      it 'uploads the 0781 documents to EVSS' do
        # AJ TODO - tried Mocking a PDF with the right format, but it gets deleted in the codebase.
        # allow_any_instance_of(described_class).to receive(:generate_stamp_pdf).and_return('spec/fixtures/pdf_fill/21-0781/simple.pdf')

        allow_any_instance_of(EVSSSupplementalDocumentUploadProvider).to receive(:generate_upload_document).and_return(evss_claim_document)

        expect_any_instance_of(EVSS::DocumentsService).to receive(:upload)
          .with(
            anything, # file_body arg
            evss_claim_document
          )
        perform_upload
      end

      it 'logs the upload attempt with the correct job prefix' do
        expect(StatsD).to receive(:increment).with(
          "#{expected_statsd_metrics_prefix}.upload_attempt"
        )

        perform_upload
      end

      it 'increments the correct StatsD success metric' do
        expect(StatsD).to receive(:increment).with(
          "#{expected_statsd_metrics_prefix}.upload_success"
        )

        perform_upload
      end

      context 'when an upload raises an EVSS response error' do
        it 'logs an upload error' do
          allow_any_instance_of(EVSS::DocumentsService).to receive(:upload).and_raise(EVSS::ErrorMiddleware::EVSSError)
          expect_any_instance_of(EVSSSupplementalDocumentUploadProvider).to receive(:log_upload_failure)

          expect do
            subject.perform_async(submission.id)
            described_class.drain
          end.to raise_error(EVSS::ErrorMiddleware::EVSSError)
        end
      end
    end
  end

  context 'catastrophic failure state' do
    describe 'when all retries are exhausted' do
      let!(:form526_submission) { create(:form526_submission) }
      let!(:form526_job_status) { create(:form526_job_status, :retryable_error, form526_submission:, job_id: 1) }

      it 'updates a StatsD counter and updates the status on an exhaustion event' do
        subject.within_sidekiq_retries_exhausted_block({ 'jid' => form526_job_status.job_id }) do
          # Will receieve increment for failure mailer metric
          allow(StatsD).to receive(:increment).with(
            'shared.sidekiq.default.EVSS_DisabilityCompensationForm_Form0781DocumentUploadFailureEmail.enqueue'
          )

          expect(StatsD).to receive(:increment).with("#{subject::STATSD_KEY_PREFIX}.exhausted")
          expect(Rails).to receive(:logger).and_call_original
        end
        form526_job_status.reload
        expect(form526_job_status.status).to eq(Form526JobStatus::STATUS[:exhausted])
      end

      context 'when an error occurs during exhaustion handling and FailureEmail fails to enqueue' do
        let!(:failure_email) { EVSS::DisabilityCompensationForm::Form0781DocumentUploadFailureEmail }
        let!(:zsf_tag) { Form526Submission::ZSF_DD_TAG_SERVICE }
        let!(:zsf_monitor) { ZeroSilentFailures::Monitor.new(zsf_tag) }

        before do
          Flipper.enable(:form526_send_0781_failure_notification)
          allow(ZeroSilentFailures::Monitor).to receive(:new).with(zsf_tag).and_return(zsf_monitor)
        end

        it 'logs a silent failure' do
          expect(zsf_monitor).to receive(:log_silent_failure).with(
            {
              job_id: form526_job_status.job_id,
              error_class: nil,
              error_message: 'An error occured',
              timestamp: instance_of(Time),
              form526_submission_id: form526_submission.id
            },
            nil,
            call_location: instance_of(ZeroSilentFailures::Monitor::CallLocation)
          )

          args = { 'jid' => form526_job_status.job_id, 'args' => [form526_submission.id] }

          expect do
            subject.within_sidekiq_retries_exhausted_block(args) do
              allow(failure_email).to receive(:perform_async).and_raise(StandardError, 'Simulated error')
            end
          end.to raise_error(StandardError, 'Simulated error')
        end
      end

      context 'when the form526_send_0781_failure_notification Flipper is enabled' do
        before do
          Flipper.enable(:form526_send_0781_failure_notification)
        end

        it 'enqueues a failure notification mailer to send to the veteran' do
          subject.within_sidekiq_retries_exhausted_block(
            {
              'jid' => form526_job_status.job_id,
              'args' => [form526_submission.id]
            }
          ) do
            expect(EVSS::DisabilityCompensationForm::Form0781DocumentUploadFailureEmail)
              .to receive(:perform_async).with(form526_submission.id)
          end
        end
      end

      context 'when the form526_send_0781_failure_notification Flipper is disabled' do
        before do
          Flipper.disable(:form526_send_0781_failure_notification)
        end

        it 'does not enqueue a failure notification mailer to send to the veteran' do
          subject.within_sidekiq_retries_exhausted_block(
            {
              'jid' => form526_job_status.job_id,
              'args' => [form526_submission.id]
            }
          ) do
            expect(EVSS::DisabilityCompensationForm::Form0781DocumentUploadFailureEmail)
              .not_to receive(:perform_async)
          end
        end
      end
    end
  end
end
