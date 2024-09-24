# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe 'AccreditedRepresentativePortal::V0::Form21a', type: :request do
  let(:valid_json) { { field: 'value' }.to_json }
  let(:invalid_json) { 'invalid json' }
  let(:representative_user) { create(:representative_user) }

  before do
    Flipper.enable(:accredited_representative_portal_pilot)
    login_as(representative_user)
  end

  describe 'POST /accredited_representative_portal/v0/form21a' do
    context 'with valid JSON' do
      let!(:in_progress_form) { create(:in_progress_form, form_id: '21a', user_uuid: representative_user.uuid) }

      it 'logs a successful submission and destroys in-progress form' do
        get('/accredited_representative_portal/v0/in_progress_forms/21a')
        expect(response).to have_http_status(:ok)
        expect(parsed_response.keys).to contain_exactly('formData', 'metadata')

        allow(AccreditationService).to receive(:submit_form21a).and_return(
          instance_double(Faraday::Response, success?: true, body: { result: 'success' }.to_json, status: 200)
        )

        expect(Rails.logger).to receive(:info).with(
          'Form21aController: Form 21a successfully submitted to OGC service ' \
          "by user with user_uuid=#{representative_user.uuid} - Response: {\"result\":\"success\"}"
        )

        headers = { 'Content-Type' => 'application/json' }
        post('/accredited_representative_portal/v0/form21a', params: valid_json, headers:)

        expect(response).to have_http_status(:ok)
        expect(parsed_response).to eq('result' => 'success')

        get('/accredited_representative_portal/v0/in_progress_forms/21a')
        expect(response).to have_http_status(:ok)
        expect(parsed_response).to eq({})
      end
    end

    context 'with invalid JSON' do
      it 'logs the error and returns a bad request status' do
        expect(Rails.logger).to receive(:error).with(
          "Form21aController: Invalid JSON in request body for user with user_uuid=#{representative_user.uuid}"
        )

        headers = { 'Content-Type' => 'application/json' }
        post('/accredited_representative_portal/v0/form21a', params: invalid_json, headers:)

        expect(response).to have_http_status(:bad_request)
        expect(parsed_response).to eq('errors' => 'Invalid JSON')
      end
    end

    context 'when service returns a blank response' do
      it 'logs the error and returns no content status' do
        allow(AccreditationService).to receive(:submit_form21a).and_return(
          instance_double(Faraday::Response, success?: false, body: nil, status: 204)
        )

        expect(Rails.logger).to receive(:info).with(
          "Form21aController: Blank response from OGC service for user with user_uuid=#{representative_user.uuid}"
        )

        headers = { 'Content-Type' => 'application/json' }
        post('/accredited_representative_portal/v0/form21a', params: valid_json, headers:)

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when service fails to parse response' do
      it 'logs the error and returns a bad gateway status' do
        allow(AccreditationService).to receive(:submit_form21a).and_return(
          instance_double(Faraday::Response, success?: false, body: { errors: 'Failed to parse response' }.to_json,
                                             status: 502)
        )

        expect(Rails.logger).to receive(:error).with(
          'Form21aController: Failed to parse response from external OGC service ' \
          "for user with user_uuid=#{representative_user.uuid}"
        )

        headers = { 'Content-Type' => 'application/json' }
        post('/accredited_representative_portal/v0/form21a', params: valid_json, headers:)

        expect(response).to have_http_status(:bad_gateway)
        expect(parsed_response).to eq('errors' => 'Failed to parse response')
      end
    end

    context 'when an unexpected error occurs' do
      it 'logs the error and returns an internal server error status' do
        allow_any_instance_of(AccreditedRepresentativePortal::V0::Form21aController)
          .to receive(:parse_request_body).and_raise(StandardError, 'Unexpected error')

        allow(Rails.logger).to receive(:error).and_call_original

        post '/accredited_representative_portal/v0/form21a'

        expect(Rails.logger).to have_received(:error).with(
          "ARP: Unexpected error occurred for user with user_uuid=#{representative_user.uuid} - Unexpected error"
        )

        expect(response).to have_http_status(:internal_server_error)
        expect(parsed_response).to match(
          'errors' => [
            {
              'title' => 'Internal server error',
              'detail' => 'Internal server error',
              'code' => '500',
              'status' => '500',
              'meta' => a_hash_including(
                'exception' => 'Unexpected error',
                'backtrace' => be_an(Array)
              )
            }
          ]
        )
      end
    end
  end
end
