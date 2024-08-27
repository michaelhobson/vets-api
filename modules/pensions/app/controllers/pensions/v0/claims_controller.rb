# frozen_string_literal: true

require 'pensions/tag_sentry'
require 'pensions/monitor'

##
# Pensions Module
#
module Pensions
  ##
  # V0 API
  #
  module V0
    ##
    # The pensions claim controller that handles form submissions
    #
    class ClaimsController < ApplicationController
      skip_before_action(:authenticate)
      before_action :load_user, only: :create
      before_action :check_flipper_flag

      service_tag 'pension-application'

      # an identifier that matches the parameter that the form will be set as in the JSON submission.
      def short_name
        'pension_claim'
      end

      ##
      # a subclass of SavedClaim, runs json-schema validations and performs any storage and attachment processing
      #
      def claim_class
        Pensions::SavedClaim
      end

      ##
      # GET serialized pension form data
      #
      def show
        claim = claim_class.find_by!(guid: params[:id]) # raises ActiveRecord::RecordNotFound
        render json: SavedClaimSerializer.new(claim)
      rescue ActiveRecord::RecordNotFound => e
        pension_monitor.track_show404(params[:id], current_user, e)
        render(json: { error: e.to_s }, status: :not_found)
      rescue => e
        pension_monitor.track_show_error(params[:id], current_user, e)
        raise e
      end

      # POST creates and validates an instance of `claim_class`
      def create
        Pensions::TagSentry.tag_sentry

        claim = claim_class.new(form: filtered_params[:form])
        pension_monitor.track_create_attempt(claim, current_user)

        in_progress_form = current_user ? InProgressForm.form_for_user(claim.form_id, current_user) : nil
        claim.form_start_date = in_progress_form.created_at if in_progress_form

        unless claim.save
          log_validation_error_to_metadata(in_progress_form, claim)
          raise Common::Exceptions::ValidationErrors, claim.errors
        end

        claim.upload_to_lighthouse(current_user)

        pension_monitor.track_create_success(in_progress_form, claim, current_user)

        clear_saved_form(claim.form_id)
        render json: SavedClaimSerializer.new(claim)
      rescue => e
        pension_monitor.track_create_error(in_progress_form, claim, current_user, e)
        raise e
      end

      private

      # Raises an exception if the pension module enabled flipper flag isn't enabled.
      def check_flipper_flag
        raise Common::Exceptions::Forbidden unless Flipper.enabled?(:pension_module_enabled, current_user)
      end

      # Filters out the parameters to form access.
      def filtered_params
        params.require(short_name.to_sym).permit(:form)
      end

      ##
      # include validation error on in_progress_form metadata.
      # `noop` if in_progress_form is `blank?`
      #
      # @param in_progress_form [InProgressForm]
      # @param claim [Pensions::SavedClaim]
      #
      def log_validation_error_to_metadata(in_progress_form, claim)
        return if in_progress_form.blank?

        metadata = in_progress_form.metadata
        metadata['submission']['error_message'] = claim&.errors&.errors&.to_s
        in_progress_form.update(metadata:)
      end

      ##
      # retreive a monitor for tracking
      #
      # @return [Pensions::Monitor]
      #
      def pension_monitor
        @monitor ||= Pensions::Monitor.new
      end
    end
  end
end
