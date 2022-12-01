# frozen_string_literal: true

module VANotify
  class Veteran
    class UnsupportedForm < StandardError; end
    class MPIError < StandardError; end
    class MPINameError < StandardError; end

    def initialize(in_progress_form)
      @in_progress_form = in_progress_form
    end

    def icn
      @icn ||= in_progress_form&.user_account&.icn
    end
    alias mhv_icn icn

    def first_name
      @first_name ||= case in_progress_form.form_id
                      when '686C-674'
                        JSON.parse(in_progress_form.form_data).dig('veteran_information', 'full_name', 'first')
                      when '1010ez'
                        JSON.parse(in_progress_form.form_data).dig('veteran_full_name', 'first')
                      when '21-526EZ'
                        lookup_first_name_by_icn
                      else
                        raise UnsupportedForm,
                              "Unsupported form: #{in_progress_form.form_id} - InProgressForm: #{in_progress_form.id}"
                      end
    end

    def authn_context
      'va_notify_lookup'
    end

    def user_uuid
      @user_uuid ||= in_progress_form.user_uuid
    end
    alias uuid user_uuid

    def verified?
      icn.present?
    end
    alias loa3? verified?

    private

    attr_reader :in_progress_form

    def lookup_first_name_by_icn
      mpi_profile = MPI::Service.new.find_profile(self)
      raise MPIError unless mpi_profile.ok?

      given_names = mpi_profile.profile.given_names
      raise MPINameError if given_names.blank?

      given_names.first
    end
  end
end
