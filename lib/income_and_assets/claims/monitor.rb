# frozen_string_literal: true

module IncomeAndAssets
  ##
  # IncomeAndAssets api monitor functions for Rails logging and StatsD
  #
  module Claims
    class Monitor
      # statsd key for api
      CLAIM_STATS_KEY = 'api.income_and_assets'

      ##
      # log GET 404 from controller
      # @see IncomeAndAssetsClaimsController
      #
      # @param confirmation_number [UUID] saved_claim guid
      # @param current_user [User]
      # @param e [ActiveRecord::RecordNotFound]
      #
      def track_show404(confirmation_number, user_account_uuid, e)
        context = {
          confirmation_number:,
          user_account_uuid:,
          message: e&.message
        }
        Rails.logger.error('21P-0969 claim not found', context)
      end

      ##
      # log GET 500 from controller
      # @see IncomeAndAssetsClaimsController
      #
      # @param confirmation_number [UUID] saved_claim guid
      # @param current_user [User]
      # @param e [Error]
      #
      def track_show_error(confirmation_number, user_account_uuid, e)
        context = {
          confirmation_number:,
          user_account_uuid:,
          message: e&.message
        }
        Rails.logger.error('21P-0969 fetching claim failed', context)
      end

      ##
      # log POST processing started
      # @see IncomeAndAssetsClaimsController
      #
      # @param claim [SavedClaim::IncomeAndAssets]
      # @param current_user [User]
      #
      def track_create_attempt(claim, user_account_uuid)
        StatsD.increment("#{CLAIM_STATS_KEY}.attempt")
        context = {
          confirmation_number: claim&.confirmation_number,
          user_account_uuid:
        }
        Rails.logger.info('21P-0969 claim creation begun', context)
      end

      ##
      # log POST processing failure
      # @see IncomeAndAssetsClaimsController
      #
      # @param in_progress_form [InProgressForm]
      # @param claim [SavedClaim::IncomeAndAssets]
      # @param current_user [User]
      # @param e [Error]
      #
      def track_create_error(in_progress_form_id, claim, user_account_uuid, e = nil)
        StatsD.increment("#{CLAIM_STATS_KEY}.failure")
        context = {
          confirmation_number: claim&.confirmation_number,
          user_account_uuid:,
          in_progress_form_id:,
          errors: claim&.errors&.errors,
          message: e&.message
        }
        Rails.logger.error('21P-0969 claim creation failed', context)
      end

      ##
      # log POST processing success
      # @see IncomeAndAssetsClaimsController
      #
      # @param in_progress_form [InProgressForm]
      # @param claim [SavedClaim::IncomeAndAssets]
      # @param current_user [User]
      #
      def track_create_success(in_progress_form_id, claim, user_account_uuid)
        StatsD.increment("#{CLAIM_STATS_KEY}.success")
        if claim.form_start_date
          StatsD.measure('saved_claim.time-to-file', claim.created_at - claim.form_start_date,
                         tags: ["form_id:#{claim.form_id}"])
        end
        Rails.logger.info('21P-0969 claim creation success',
                          { confirmation_number: claim&.confirmation_number, user_account_uuid:,
                            in_progress_form_id: })
      end
    end
  end
end