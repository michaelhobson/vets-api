# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClaimsApi::EvidenceWaiverBuilderJob, type: :job do
  subject { described_class }

  before do
    Sidekiq::Job.clear_all
  end

  let(:ews) { create(:claims_api_evidence_waiver_submission, :with_full_headers_tamara) }

  describe 'when an errored job has a 48 hour time limitation' do
    it 'expires in 48 hours' do
      described_class.within_sidekiq_retries_exhausted_block do
        expect(subject).to be_expired_in 48.hours
      end
    end
  end

  describe '#retry_limits_for_notification' do
    it "provides the method definition for sidekiq 'retry_monitoring.rb'" do
      res = described_class.new.retry_limits_for_notification
      expect(res).to eq([11])
      expect(described_class.new.respond_to?(:retry_limits_for_notification)).to eq(true)
    end
  end

  describe 'when an errored job has exhausted its retries' do
    it 'logs to the ClaimsApi Logger' do
      error_msg = 'An error occurred from the Evidence Waiver Builder Job'
      msg = { 'args' => [ews.id],
              'class' => described_class,
              'error_message' => error_msg }

      described_class.within_sidekiq_retries_exhausted_block(msg) do
        expect(ClaimsApi::Logger).to receive(:log).with(
          'claims_api_retries_exhausted',
          record_id: ews.id,
          detail: "Job retries exhausted for #{described_class}",
          error: error_msg
        )
      end
    end
  end
end
