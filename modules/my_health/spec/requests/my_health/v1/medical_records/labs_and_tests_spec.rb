# frozen_string_literal: true

require 'rails_helper'
require 'support/mr_client_helpers'
require 'medical_records/client'
require 'medical_records/bb_internal/client'
require 'support/shared_examples_for_mhv'

RSpec.describe 'MyHealth::V1::MedicalRecords::LabsAndTests', type: :request do
  include MedicalRecords::ClientHelpers
  include SchemaMatchers

  let(:user_id) { '11898795' }
  let(:va_patient) { true }
  let(:current_user) { build(:user, :mhv, va_patient:, mhv_account_type:) }

  before do
    allow(MedicalRecords::Client).to receive(:new).and_return(authenticated_client)
    allow(BBInternal::Client).to receive(:new).and_return(authenticated_client)
    sign_in_as(current_user)
  end

  context 'Basic User' do
    let(:mhv_account_type) { 'Basic' }

    before { get '/my_health/v1/medical_records/labs_and_tests' }

    include_examples 'for user account level', message: 'You do not have access to medical records'
    include_examples 'for non va patient user', authorized: false, message: 'You do not have access to medical records'
  end

  context 'Advanced User' do
    let(:mhv_account_type) { 'Advanced' }

    before { get '/my_health/v1/medical_records/labs_and_tests' }

    include_examples 'for user account level', message: 'You do not have access to medical records'
    include_examples 'for non va patient user', authorized: false, message: 'You do not have access to medical records'
  end

  context 'Premium User' do
    let(:mhv_account_type) { 'Premium' }

    before do
      VCR.insert_cassette('user_eligibility_client/perform_an_eligibility_check_for_premium_user',
                          match_requests_on: %i[method sm_user_ignoring_path_param])
    end

    after do
      VCR.eject_cassette
    end

    context 'not a va patient' do
      before { get '/my_health/v1/medical_records/labs_and_tests' }

      let(:va_patient) { false }
      let(:current_user) do
        build(:user, :mhv, :no_vha_facilities, va_patient:, mhv_account_type:)
      end

      include_examples 'for non va patient user', authorized: false,
                                                  message: 'You do not have access to medical records'
    end

    it 'responds to GET #index' do
      VCR.use_cassette('mr_client/get_a_list_of_chemhem_labs') do
        VCR.use_cassette('mr_client/get_a_list_of_diagreport_labs') do
          VCR.use_cassette('mr_client/get_a_list_of_docref_labs') do
            get '/my_health/v1/medical_records/labs_and_tests'
          end
        end
      end

      expect(response).to be_successful
      expect(response.body).to be_a(String)
    end

    it 'responds to GET #show' do
      VCR.use_cassette('mr_client/get_a_single_lab_or_test') do
        get '/my_health/v1/medical_records/labs_and_tests/40766'
      end

      expect(response).to be_successful
      expect(response.body).to be_a(String)
    end

    context 'when the patient is not found' do
      before do
        allow_any_instance_of(MedicalRecords::Client).to receive(:list_labs_and_tests)
          .and_raise(MedicalRecords::PatientNotFound)
        allow_any_instance_of(MedicalRecords::Client).to receive(:get_diagnostic_report)
          .and_raise(MedicalRecords::PatientNotFound)
      end

      it 'returns a 202 Accepted response for GET #index' do
        get '/my_health/v1/medical_records/labs_and_tests'
        expect(response).to have_http_status(:accepted)
      end

      it 'returns a 202 Accepted response for GET #show' do
        get '/my_health/v1/medical_records/labs_and_tests/40766'
        expect(response).to have_http_status(:accepted)
      end
    end
  end
end
