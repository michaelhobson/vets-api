class FormProfiles::VA686c674v2 < FormProfile
    class FormAddress
      include Virtus.model
  
      attribute :country_name, String
      attribute :address_line1, String
      attribute :address_line2, String
      attribute :address_line3, String
      attribute :city, String
      attribute :state_code, String
      attribute :province, String
      attribute :zip_code, String
      attribute :international_postal_code, String
    end
  
    attribute :form_address
  
    def prefill
      prefill_form_address
  
      super
    end
  
    def metadata
      {
        version: 0,
        prefill: true,
        returnUrl: '/686-options-selection'
      }
    end
  
    private
  
    def prefill_form_address
      mailing_address = begin
        VAProfileRedis::ContactInformation.for_user(user).mailing_address if user.vet360_id.present?
      rescue
        nil
      end
        
      return if mailing_address.blank?
  
      @form_address = FormAddress.new(
        mailing_address.to_h.slice(
          :address_line1,
          :address_line2,
          :address_line3,
          :city,
          :state_code,
          :province,
          :zip_code,
          :international_postal_code
        ).merge(country_name: mailing_address.country_code_iso3)
      )
    end

    def va_file_number_last_four
        response = BGS::People::Request.new.find_person_by_participant_id(user:)
        (
          response.file_number.presence || user.ssn.presence
        )&.last(4)
      end
  end
  