# frozen_string_literal: true

require 'sidekiq'
require 'decision_review_v1/service'

module DecisionReview
  class SavedClaimScStatusUpdaterJob
    include Sidekiq::Job

    # No need to retry since the schedule will run this every hour
    sidekiq_options retry: false, unique_for: 30.minutes

    RETENTION_PERIOD = 59.days

    SUCCESSFUL_STATUS = %w[complete].freeze

    ERROR_STATUS = 'error'

    UPLOAD_SUCCESSFUL_STATUS = %w[vbms].freeze

    ATTRIBUTES_TO_STORE = %w[status detail createDate updateDate].freeze

    STATSD_KEY_PREFIX = 'worker.decision_review.saved_claim_sc_status_updater'

    def perform
      return unless enabled? && supplemental_claims.present?

      StatsD.increment("#{STATSD_KEY_PREFIX}.processing_records", supplemental_claims.size)

      supplemental_claims.each do |sc|
        status, attributes = get_status_and_attributes(sc.guid)
        uploads_metadata = get_evidence_uploads_statuses(sc.guid)
        secondary_forms_complete = get_and_update_secondary_form_statuses(sc.guid)

        timestamp = DateTime.now
        params = { metadata: attributes.merge(uploads: uploads_metadata).to_json, metadata_updated_at: timestamp }
        # only set delete date if attachments are all successful as well
        if saved_claim_complete?(sc, status, uploads_metadata, secondary_forms_complete)
          params[:delete_date] = timestamp + RETENTION_PERIOD
          StatsD.increment("#{STATSD_KEY_PREFIX}.delete_date_update")
        else
          handle_form_status_metrics_and_logging(sc, status)
        end

        sc.update(params)
      rescue => e
        StatsD.increment("#{STATSD_KEY_PREFIX}.error")
        Rails.logger.error('DecisionReview::SavedClaimScStatusUpdaterJob error', { guid: sc.guid, message: e.message })
      end

      nil
    end

    private

    def decision_review_service
      @service ||= DecisionReviewV1::Service.new
    end

    def supplemental_claims
      @supplemental_claims ||= ::SavedClaim::SupplementalClaim.where(delete_date: nil).order(created_at: :asc)
    end

    def get_status_and_attributes(guid)
      response = decision_review_service.get_supplemental_claim(guid).body
      attributes = response.dig('data', 'attributes')
      status = attributes['status']

      [status, attributes]
    end

    def get_evidence_uploads_statuses(submitted_appeal_uuid)
      result = []

      attachment_ids = AppealSubmission.find_by(submitted_appeal_uuid:)&.appeal_submission_uploads
                                       &.pluck(:lighthouse_upload_id) || []

      attachment_ids.each do |uuid|
        response = decision_review_service.get_supplemental_claim_upload(uuid:).body
        attributes = response.dig('data', 'attributes').slice(*ATTRIBUTES_TO_STORE)
        result << attributes.merge('id' => uuid)
      end

      result
    end

    def get_and_update_secondary_form_statuses(submitted_appeal_uuid)
      all_complete = true
      return all_complete unless Flipper.enabled?(:decision_review_track_4142_submissions)

      secondary_forms = AppealSubmission.find_by(submitted_appeal_uuid:)&.secondary_appeal_forms
      secondary_forms = secondary_forms&.filter { |form| form.delete_date.nil? } || []

      secondary_forms.each do |form|
        response = decision_review_service.get_supplemental_claim_upload(uuid: form.guid).body
        attributes = response.dig('data', 'attributes').slice(*ATTRIBUTES_TO_STORE)
        all_complete = false unless UPLOAD_SUCCESSFUL_STATUS.include?(attributes['status'])
        handle_secondary_form_status_metrics_and_logging(form, attributes['status'])
        update_secondary_form_status(form, attributes)
      end

      all_complete
    end

    def handle_form_status_metrics_and_logging(sc, status)
      # Skip logging and statsd metrics when there is no status change
      return if JSON.parse(sc.metadata || '{}')['status'] == status

      if status == ERROR_STATUS
        Rails.logger.info('DecisionReview::SavedClaimScStatusUpdaterJob form status error', guid: sc.guid)
        tags = ['service:supplemental-claims', 'function: form submission to Lighthouse']
        StatsD.increment('silent_failure', tags:)
      end

      StatsD.increment("#{STATSD_KEY_PREFIX}.status", tags: ["status:#{status}"])
    end

    def handle_secondary_form_status_metrics_and_logging(form, status)
      # Skip logging and statsd metrics when there is no status change
      return if JSON.parse(form.status || '{}')['status'] == status

      if status == ERROR_STATUS
        Rails.logger.info('DecisionReview::SavedClaimScStatusUpdaterJob secondary form status error', guid: form.guid)
        tags = ['service:supplemental-claims-4142', 'function: PDF submission to Lighthouse']
        StatsD.increment('silent_failure', tags:)
      end

      StatsD.increment("#{STATSD_KEY_PREFIX}_secondary_form.status", tags: ["status:#{status}"])
    end

    def update_secondary_form_status(form, attributes)
      status = attributes['status']
      if UPLOAD_SUCCESSFUL_STATUS.include?(status)
        StatsD.increment("#{STATSD_KEY_PREFIX}_secondary_form.delete_date_update")
        delete_date = (Time.current + RETENTION_PERIOD)
      else
        delete_date = nil
      end
      form.update!(status: attributes.to_json, status_updated_at: Time.current, delete_date:)
    end

    def check_attachments_status(sc, uploads_metadata)
      result = true

      old_uploads_metadata = extract_uploads_metadata(sc.metadata)

      uploads_metadata.each do |upload|
        status = upload['status']
        upload_id = upload['id']
        result = false unless UPLOAD_SUCCESSFUL_STATUS.include? status

        # Skip logging and statsd metrics when there is no status change
        next if old_uploads_metadata.dig(upload_id, 'status') == status

        if status == ERROR_STATUS
          Rails.logger.info('DecisionReview::SavedClaimScStatusUpdaterJob evidence status error',
                            { guid: sc.guid, lighthouse_upload_id: upload_id, detail: upload['detail'] })
          tags = ['service:supplemental-claims', 'function: evidence submission to Lighthouse']
          StatsD.increment('silent_failure', tags:)
        end
        StatsD.increment("#{STATSD_KEY_PREFIX}_upload.status", tags: ["status:#{status}"])
      end

      result
    end

    def saved_claim_complete?(sc, status, uploads_metadata, secondary_forms_complete)
      check_attachments_status(sc, uploads_metadata) && secondary_forms_complete && SUCCESSFUL_STATUS.include?(status)
    end

    def extract_uploads_metadata(metadata)
      return {} if metadata.nil?

      JSON.parse(metadata).fetch('uploads', []).index_by { |upload| upload['id'] }
    end

    def enabled?
      Flipper.enabled? :decision_review_saved_claim_sc_status_updater_job_enabled
    end
  end
end
