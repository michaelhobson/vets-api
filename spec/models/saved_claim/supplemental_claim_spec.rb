# frozen_string_literal: true

require 'rails_helper'
require 'decision_review_v1/service'

RSpec.describe SavedClaim::SupplementalClaim, type: :model do
  subject { described_class.new }

  describe 'AppealSubmission association' do
    let(:guid) { SecureRandom.uuid }
    let(:form_data) do
      { stuff: 'things' }
    end
    let!(:appeal_submission) { create(:appeal_submission, type_of_appeal: 'SC', submitted_appeal_uuid: guid) }
    let!(:saved_claim_sc) do
      SavedClaim::SupplementalClaim.create!(
        form_id: '20-0995',
        guid: guid,
        form: form_data.to_json,
        form_start_date: Time.current
      )
    end

    it 'has one AppealSubmission' do
      expect(saved_claim_sc.appeal_submission).to eq appeal_submission
    end

    it 'can be accessed from the AppealSubmission' do
      expect(appeal_submission.saved_claim_sc).to eq saved_claim_sc
    end
  end
end
