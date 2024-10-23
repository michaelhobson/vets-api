# frozen_string_literal: true

require 'sidekiq'

module Crm
  class TopicsDataJob
    include Sidekiq::Job

    # Schedule to run every 24 hours. Adjust as needed.
    sidekiq_options retry: false, unique_for: 24.hours

    def perform
      Crm::CacheData.new.fetch_and_cache_data(endpoint: 'topics', cache_key: 'categories_topics_subtopics', payload: {})
    rescue => e
      log_error('topics', e)
    end

    private

    def log_error(action, exception)
      LogService.new.call(action) do |span|
        span.set_tag('error', true)
        span.set_tag('error.msg', exception.message)
      end
      Rails.logger.error("Error during #{action}: #{exception.message}")
    end
  end
end