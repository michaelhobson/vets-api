# frozen_string_literal: true

require 'rails_helper'
require './modules/decision_reviews/spec/sidekiq/shared_examples_for_status_updater_jobs'

RSpec.describe DecisionReviews::HlrStatusUpdaterJob, type: :job do
  subject { described_class }

  include_context 'status updater job context', SavedClaim::HigherLevelReview

  describe 'perform' do
    context 'with flag enabled', :aggregate_failures do
      before do
        Flipper.enable :decision_review_saved_claim_hlr_status_updater_job_enabled
      end

      include_examples 'status updater job with base forms', SavedClaim::HigherLevelReview
    end

    context 'with flag disabled' do
      before do
        Flipper.disable :decision_review_saved_claim_hlr_status_updater_job_enabled
      end

      it 'does not query SavedClaim::HigherLevelReview records' do
        expect(SavedClaim::HigherLevelReview).not_to receive(:where)

        subject.new.perform
      end
    end
  end
end
