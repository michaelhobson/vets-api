# frozen_string_literal: true

require 'common/client/base'
require 'common/client/concerns/monitoring'

module VAOS
  class BaseService < Common::Client::Base
    include Common::Client::Concerns::Monitoring
    include SentryLogging

    STATSD_KEY_PREFIX = 'api.vaos'

    def patch(path, params, headers, options)
      request(:patch, path, params, headers, options)
    end

    private

    def config
      VAOS::Configuration.instance
    end

    # Set the referrer (Referer header) to distinguish review instance, staging, etc from logs
    def referrer
      if Settings.hostname.ends_with?('.gov')
        "https://#{Settings.hostname}".gsub('vets', 'va')
      else
        'https://review-instance.va.gov' # VAMF rejects Referer that is not valid; such as those of review instances
      end
    end

    def base_vaos_route
      #  This will not be used until the alt route is updated and has full test coverage
      if Flipper.enabled?(:va_online_scheduling_vaos_alternate_route, user)
        'vaos-alt/v1'
      else
        'vaos/v1'
      end
    end
  end
end
