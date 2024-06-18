# frozen_string_literal: true

require 'sidekiq'

module CheckIn
  class TravelClaimSubmissionWorker
    include Sidekiq::Job
    include SentryLogging

    sidekiq_options retry: false

    def perform(uuid, appointment_date)
      redis_client = TravelClaim::RedisClient.build
      mobile_phone = redis_client.patient_cell_phone(uuid:)
      station_number = redis_client.station_number(uuid:)
      facility_type = redis_client.facility_type(uuid:)

      logger.info({
                    message: "Submitting travel claim for #{uuid}, #{appointment_date}, " \
                             "#{station_number}, #{facility_type}",
                    uuid:,
                    appointment_date:,
                    station_number:,
                    facility_type:
                  })

      claim_number, template_id = submit_claim(uuid:, appointment_date:, station_number:, facility_type:)

      send_notification(mobile_phone:, appointment_date:, template_id:, claim_number:, facility_type:)
      StatsD.increment(Constants::STATSD_NOTIFY_SUCCESS)
    end

    def submit_claim(opts = {})
      check_in_session = CheckIn::V2::Session.build(data: { uuid: opts[:uuid] })

      claims_resp = TravelClaim::Service.build(
        check_in: check_in_session,
        params: { appointment_date: opts[:appointment_date] }
      ).submit_claim

      handle_response(claims_resp:, facility_type: opts[:facility_type])
    rescue => e
      logger.error({ message: "Error calling BTSSS Service: #{e.message}" }.merge(opts))
      if 'oh'.casecmp?(opts[:facility_type])
        StatsD.increment(Constants::OH_STATSD_BTSSS_ERROR)
        template_id = Constants::OH_ERROR_TEMPLATE_ID
      else
        StatsD.increment(Constants::CIE_STATSD_BTSSS_ERROR)
        template_id = Constants::CIE_ERROR_TEMPLATE_ID
      end
      [nil, template_id]
    end

    # rubocop:disable Metrics/MethodLength
    def handle_response(opts = {})
      claim_number = opts[:claims_resp]&.dig(:data, :claimNumber)&.last(4)
      code = opts[:claims_resp]&.dig(:data, :code)
      facility_type = opts[:facility_type] || ''

      statsd_metric, template_id = case facility_type.downcase
                                   when 'oh'
                                     case code
                                     when TravelClaim::Response::CODE_SUCCESS
                                       [Constants::OH_STATSD_BTSSS_SUCCESS, Constants::OH_SUCCESS_TEMPLATE_ID]
                                     when TravelClaim::Response::CODE_CLAIM_EXISTS
                                       [Constants::OH_STATSD_BTSSS_DUPLICATE, Constants::OH_DUPLICATE_TEMPLATE_ID]
                                     when TravelClaim::Response::CODE_BTSSS_TIMEOUT
                                       [Constants::OH_STATSD_BTSSS_TIMEOUT, Constants::OH_TIMEOUT_TEMPLATE_ID]
                                     else
                                       [Constants::OH_STATSD_BTSSS_ERROR, Constants::OH_ERROR_TEMPLATE_ID]
                                     end
                                   else
                                     case code
                                     when TravelClaim::Response::CODE_SUCCESS
                                       [Constants::CIE_STATSD_BTSSS_SUCCESS, Constants::CIE_SUCCESS_TEMPLATE_ID]
                                     when TravelClaim::Response::CODE_CLAIM_EXISTS
                                       [Constants::CIE_STATSD_BTSSS_DUPLICATE, Constants::CIE_DUPLICATE_TEMPLATE_ID]
                                     when TravelClaim::Response::CODE_BTSSS_TIMEOUT
                                       [Constants::CIE_STATSD_BTSSS_TIMEOUT, Constants::CIE_TIMEOUT_TEMPLATE_ID]
                                     else
                                       [Constants::CIE_STATSD_BTSSS_ERROR, Constants::CIE_ERROR_TEMPLATE_ID]
                                     end
                                   end

      StatsD.increment(statsd_metric)
      [claim_number, template_id]
    end
    # rubocop:enable Metrics/MethodLength

    def send_notification(opts = {})
      notify_client = VaNotify::Service.new(Settings.vanotify.services.check_in.api_key)
      phone_last_four = opts[:mobile_phone].delete('^0-9').last(4)

      logger.info({
                    message: "Sending travel claim notification to #{phone_last_four}, #{opts[:template_id]}",
                    phone_last_four:,
                    template_id: opts[:template_id]
                  })
      appt_date_in_mmm_dd_format = DateTime.strptime(opts[:appointment_date], '%Y-%m-%d').to_date.strftime('%b %d')

      notify_client.send_sms(
        phone_number: opts[:mobile_phone],
        template_id: opts[:template_id],
        sms_sender_id: 'oh'.casecmp?(opts[:facility_type]) ? Constants::OH_SMS_SENDER_ID : Constants::CIE_SMS_SENDER_ID,
        personalisation: {
          claim_number: opts[:claim_number],
          appt_date: appt_date_in_mmm_dd_format
        }
      )
    rescue => e
      handle_error(e, opts)
      raise e
    end

    def handle_error(ex, opts = {})
      log_exception_to_sentry(
        ex,
        { phone_number: opts[:mobile_phone].delete('^0-9').last(4), template_id: opts[:template_id],
          claim_number: opts[:claim_number] },
        { error: :check_in_va_notify_job, team: 'check-in' }
      )
      StatsD.increment(Constants::STATSD_NOTIFY_ERROR)
    end
  end
end