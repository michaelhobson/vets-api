# frozen_string_literal: true

require 'common/exceptions/validation_errors'
require 'va_profile/contact_information/service'
require 'va_profile/profile_information/service'

module Vet360
  module Writeable
    extend ActiveSupport::Concern

    # For the passed VAProfile model type and params, it:
    #   - builds and validates a VAProfile models
    #   - POSTs/PUTs the model data to VAProfile
    #   - creates a new AsyncTransaction db record, based on the type
    #   - renders the transaction through the base serializer
    #
    # @param type [String] the VAProfile::Models type (i.e. 'Email', 'Address', etc.)
    # @param params [ActionController::Parameters ] The strong params from the controller
    # @param http_verb [String] The type of write request being made to VAProfile ('post' or 'put')
    # @return [Response] Normal controller `render json:` response with a response.body, .status, etc.
    #
    def write_to_vet360_and_render_transaction!(type, params, http_verb: 'post')
      record = build_record(type, params)
      validate!(record)
      if Flipper.enabled?(:va_profile_information_v3_service, @current_user) && http_verb == ('update')
        http_verb = build_http_verb(record)
      end

      response = write_valid_record!(http_verb, type, record)
      render_new_transaction!(type, response)
    end

    def invalidate_cache
      VAProfileRedis::Cache.invalidate(@current_user)
    end

    def build_record(type, params)
      "VAProfile::Models::#{type.capitalize}"
        .constantize
        .new(params)
        .set_defaults(@current_user)
    end

    private

    def validate!(record)
      return if record.valid?

      PersonalInformationLog.create!(
        data: record.to_h,
        error_class: "#{record.class} ValidationError"
      )
      raise Common::Exceptions::ValidationErrors, record
    end

    def service
      if Flipper.enabled?(:va_profile_information_v3_service, @current_user)
        VAProfile::ProfileInformation::Service.new @current_user
      else
        VAProfile::ContactInformation::Service.new @current_user
      end
    end

    def write_valid_record!(http_verb, type, record)
      if Flipper.enabled?(:va_profile_information_v3_service, @current_user)
        service.send('create_or_update_info', http_verb.to_sym, record)
      else
        service.send("#{http_verb}_#{type.downcase}", record)
      end
    end

    def build_http_verb(record)
      if Flipper.enabled?(:va_profile_information_v3_redis, @current_user)
        contact_info = VAProfileRedis::ProfileInformation.for_user(@user)
      else
        contact_info = VAProfileRedis::ContactInformation.for_user(@user)
      end
      attr = record.contact_info_attr(contact_info: true)
      raise "invalid #{record.model} VAProfile::ProfileInformation" if attr.nil?

      record.id = contact_info.public_send(attr)&.id
      record.id.present? ? :put : :post
    end

    def render_new_transaction!(type, response)
      transaction = "AsyncTransaction::VAProfile::#{type.capitalize}Transaction".constantize.start(
        @current_user, response
      )
      render json: AsyncTransaction::BaseSerializer.new(transaction).serializable_hash
    end

    def add_effective_end_date(params)
      params[:effective_end_date] = Time.now.utc.iso8601
      params
    end
  end
end
