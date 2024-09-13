# frozen_string_literal: true

require 'reports/uploader'

module SimpleFormsApi
  module S3
    class Utils
      private

      def assign_instance_variables(defaults)
        defaults.each do |key, value|
          instance_variable_set("@#{key}", value)
        end
      end

      def log_info(message, **details)
        Rails.logger.info(message, details)
      end

      def log_error(message, error, **details)
        Rails.logger.error(message, details.merge(error: error.message, backtrace: error.backtrace.first(5)))
      end

      def handle_error(message, error, context)
        log_error(message, error, **context)
        raise error
      end

      def s3_resource
        @s3_resource ||= Reports::Uploader.new_s3_resource
      end

      def target_bucket
        @target_bucket ||= Reports::Uploader.s3_bucket
      end
    end
  end
end
