# frozen_string_literal: true

require 'va_profile/v2/contact_information/service'
require 'va_profile/v2/contact_information/person_response'

def stub_contact_info(user)
  service = VAProfile::V2::ContactInformation::Service.new(user)
  person_response = VAProfile::V2::ContactInformation::PersonResponse.new(200, person: user)

  allow_any_instance_of(service).to receive(:get_person).and_return(person_response)

  [person_response]
end
