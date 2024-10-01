# frozen_string_literal: true

module MPI
  module Models
    class MviProfileAddress
      include Virtus.model

      attribute :street, String
      attribute :street2, String
      attribute :city, String
      attribute :state, String
      attribute :postal_code, String
      attribute :country, String
      attribute :country_code_iso3, String
      attribute :zip_code, String
      attribute :state_code, String
      attribute :address_line1, String
      attribute :address_line2, String
    end
  end
end
