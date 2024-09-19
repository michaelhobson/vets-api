# frozen_string_literal: true

FactoryBot.define do
  factory :person_v2, class: 'VAProfile::Models::V2::Person' do
    addresses   { [FactoryBot.build(:va_profile_address_v2), FactoryBot.build(:va_profile_address_v2, :mailing)] }
    emails      { [FactoryBot.build(:email)] }
    telephones  { [FactoryBot.build(:telephone)] }
    source_date { '2018-04-09T11:52:03-06:00' }
    created_at  { '2017-04-09T11:52:03-06:00' }
    updated_at  { '2017-04-09T11:52:03-06:00' }
    vet360_id { '12345' }
  end
end
