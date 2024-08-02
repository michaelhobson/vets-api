# frozen_string_literal: true

require_relative 'address'
require_relative 'base'
require_relative 'email'
require_relative 'telephone'
require_relative 'permission'
require 'common/models/attribute_types/iso8601_time'

module VAProfile
  module Models
    class Person < Base
      attribute :addresses, Array[Address]
      attribute :created_at, Common::ISO8601Time
      attribute :emails, Array[Email]
      attribute :source_date, Common::ISO8601Time
      attribute :telephones, Array[Telephone]
      attribute :permissions, Array[Permission]
      attribute :transaction_id, String
      attribute :updated_at, Common::ISO8601Time
      attribute :vet360_id, String

      CONTACT_INFO_CHANGE_TEMPLATE = Settings.vanotify.services.va_gov.template_id.contact_info_change
      EMAIL_PERSONALISATIONS = {
        address: 'Address',
        residence_address: 'Home address',
        correspondence_address: 'Mailing address',
        email: 'Email address',
        phone: 'Phone number',
        home_phone: 'Home phone number',
        mobile_phone: 'Mobile phone number',
        work_phone: 'Work phone number'
      }.freeze

      # Converts a decoded JSON response from VAProfile to an instance of the Person model
      # @param body [Hash] the decoded response body from VAProfile
      # @return [VAProfile::Models::Person] the model built from the response body
      def self.build_from(body)
        body ||= {}
        addresses = body['addresses']&.map { |a| VAProfile::Models::Address.build_from(a) }
        emails = body['emails']&.map { |e| VAProfile::Models::Email.build_from(e) }
        telephones = body['telephones']&.map { |t| VAProfile::Models::Telephone.build_from(t) }
        permissions = body['permissions']&.map { |t| VAProfile::Models::Permission.build_from(t) }

        VAProfile::Models::Person.new(
          created_at: body['create_date'],
          source_date: body['source_date'],
          updated_at: body['update_date'],
          transaction_id: body['trx_audit_id'],
          addresses: addresses || [],
          emails: emails || [],
          telephones: telephones || [],
          permissions: permissions || [],
          vet360_id: body['vet360_id']
        )
      end

      def self.bio_path
        'profile'
      end

      def self.response_class
        VAProfile::ProfileInformation::PersonResponse
      end

      def transaction_response_class
        VAProfile::ProfileInformation::PersonTransactionResponse
      end

      def self.transaction_status_path(_user, transaction_id)
        "status/#{transaction_id}"
      end

      def self.send_change_notifications?
        false
      end

      def contact_info_attr
        nil
      end
    end
  end
end
