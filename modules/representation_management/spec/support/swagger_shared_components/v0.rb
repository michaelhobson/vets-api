# frozen_string_literal: true

module SwaggerSharedComponents
  class V0
    def self.body_examples
      {
        pdf_generator2122:,
        pdf_generator2122_parameter:
      }
    end

    def self.pdf_generator2122
      {
        organization_name: 'My Organization',
        record_consent: '',
        consent_address_change: '',
        consent_limits: [],
        claimant:,
        veteran:
      }
    end

    def self.claimant
      {
        date_of_birth: '1980-01-01',
        relationship: 'Spouse',
        phone: '5555555555',
        email: 'claimant@example.com',
        name:,
        address:
      }
    end

    def self.veteran
      {
        ssn: '123456789',
        va_file_number: '987654321',
        date_of_birth: '1970-01-01',
        service_number: '123123456',
        service_branch: 'ARMY',
        phone: '5555555555',
        email: 'veteran@example.com',
        insurance_numbers: [],
        name:,
        address:
      }
    end

    def self.pdf_generator2122_parameter
      {
        name: :pdf_generator2122,
        in: :body,
        schema: {
          type: :object,
          properties: appointment_conditions_parameter.merge(
            claimant: claimant_parameter,
            veteran: veteran_parameter
          ),
          required: %w[organization_name record_consent veteran]
        }
      }
    end

    def self.appointment_conditions_parameter
      {
        organization_name: { type: :string, example: 'Veterans Organization' },
        record_consent: { type: :boolean, example: true },
        consent_address_change: { type: :boolean, example: false },
        consent_limits: {
          type: :array,
          items: { type: :string },
          example: %w[ALCOHOLISM DRUG_ABUSE HIV SICKLE_CELL]
        },
        conditions_of_appointment: {
          type: :array,
          items: { type: :string },
          example: %w[a123 b456 c789]
        }
      }
    end

    def self.claimant_parameter
      {
        type: :object,
        properties: {
          name: name_parameters,
          address: address_parameters,
          date_of_birth: { type: :string, format: :date, example: '12/31/2000' },
          relationship: { type: :string, example: 'Spouse' },
          phone: { type: :string, example: '1234567890' },
          email: { type: :string, example: 'veteran@example.com' }
        }
      }
    end

    def self.veteran_parameter
      {
        type: :object,
        properties: {
          insurance_numbers: {
            type: :array,
            items: { type: :string },
            example: %w[123456789 987654321]
          },
          name: name_parameters,
          address: address_parameters,
          ssn: { type: :string, example: '123456789' },
          va_file_number: { type: :string, example: '123456789' },
          date_of_birth: { type: :string, format: :date, example: '12/31/2000' },
          service_number: { type: :string, example: '123456789' },
          service_branch: { type: :string, example: 'Army' },
          service_branch_other: { type: :string, example: 'Other Branch' },
          phone: { type: :string, example: '1234567890' },
          email: { type: :string, example: 'veteran@example.com' }
        }
      }
    end

    def self.name_parameters
      {
        type: :object,
        properties: {
          first: { type: :string, example: 'John' },
          middle: { type: :string, example: 'A' },
          last: { type: :string, example: 'Doe' }
        }
      }
    end

    def self.name
      {
        first: 'John',
        middle: 'A',
        last: 'Doe'
      }
    end

    def self.address_parameters
      {
        type: :object,
        properties: {
          address_line1: { type: :string, example: '123 Main St' },
          address_line2: { type: :string, example: 'Apt 1' },
          city: { type: :string, example: 'Springfield' },
          state_code: { type: :string, example: 'IL' },
          country: { type: :string, example: 'US' },
          zip_code: { type: :string, example: '62704' },
          zip_code_suffix: { type: :string, example: '1234' }
        }
      }
    end

    def self.address
      {
        address_line1: '123 Main St',
        address_line2: 'Apt 1',
        city: 'Springfield',
        state_code: 'IL',
        country: 'US',
        zip_code: '62704',
        zip_code_suffix: '1234'
      }
    end
  end
end