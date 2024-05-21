# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pega callback', type: :request do
  before do
    allow_any_instance_of(IvcChampva::V1::PegaController).to receive(:authenticate_service_account).and_return(true)
  end

  describe 'POST #update_status' do
    let(:valid_payload) do
      {
        form_uuid: '12345678-1234-5678-1234-567812345678',
        file_names: ['12345678-1234-5678-1234-567812345678_vha_10_10d-tmp.pdf',
                     '12345678-1234-5678-1234-567812345678_vha_10_10d-tmp-1.pdf'],
        status: 'Processed'
      }
    end

    context 'with valid payload' do
      it 'returns HTTP status 200 with same form_uuid but not all files' do
        IvcChampvaForm.delete_all
        IvcChampvaForm.create!(
          form_uuid: '12345678-1234-5678-1234-567812345678',
          email: 'test@email.com',
          first_name: 'Veteran',
          last_name: 'Surname',
          form_number: '10-10D',
          file_name: '12345678-1234-5678-1234-567812345678_vha_10_10d-tmp.pdf',
          s3_status: 'Submitted',
          pega_status: nil
        )

        IvcChampvaForm.create!(
          form_uuid: '12345678-1234-5678-1234-567812345678',
          email: 'test@email.com',
          first_name: 'Veteran',
          last_name: 'Surname',
          form_number: '10-10D',
          file_name: '12345678-1234-5678-1234-567812345678_vha_10_10d-tmp-1.pdf',
          s3_status: 'Submitted',
          pega_status: nil
        )

        IvcChampvaForm.create!(
          form_uuid: '12345678-1234-5678-1234-567812345678',
          email: 'test@email.com',
          first_name: 'Veteran',
          last_name: 'Surname',
          form_number: '10-10D',
          file_name: '12345678-1234-5678-1234-567812345678_vha_10_10d-tmp-2.pdf',
          s3_status: 'Submitted',
          pega_status: nil
        )

        post '/ivc_champva/v1/forms/status_updates', params: valid_payload

        ivc_forms = [IvcChampvaForm.all]
        status_array = ivc_forms.map { |form| form.pluck(:pega_status) }

        # only 2/3 should be updatedinva
        expect(status_array.flatten).not_to eq(%w[Processed Processed])
        expect(response).to have_http_status(:ok)
      end

      it 'returns HTTP status 200 with different form_uuid' do
        IvcChampvaForm.delete_all
        IvcChampvaForm.create!(
          form_uuid: 'd8f2902b-0b6e-4b8e-88d4-5f7a4a5b7f6d',
          email: 'test@email.com',
          first_name: 'Veteran',
          last_name: 'Surname',
          form_number: '10-10D',
          file_name: 'd8f2902b-0b6e-4b8e-88d4-5f7a4a5b7f6d_vha_10_10d-tmp.pdf',
          s3_status: 'Submitted',
          pega_status: nil
        )

        IvcChampvaForm.create!(
          form_uuid: '12345678-1234-5678-1234-567812345678',
          email: 'test@email.com',
          first_name: 'Veteran',
          last_name: 'Surname',
          form_number: '10-10D',
          file_name: '12345678-1234-5678-1234-567812345678_vha_10_10d-tmp.pdf',
          s3_status: 'Submitted',
          pega_status: nil
        )

        post '/ivc_champva/v1/forms/status_updates', params: valid_payload

        ivc_forms = [IvcChampvaForm.all]
        status_array = ivc_forms.map { |form| form.pluck(:pega_status) }

        expect(status_array.flatten).not_to eq(['Processed'])
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid payload' do
      let(:invalid_payload) { { status: 'invalid' } }

      it 'returns HTTP status 200' do
        post '/ivc_champva/v1/forms/status_updates', params: invalid_payload
        expect(response).to have_http_status(:ok)
      end

      it 'returns an error message' do
        post '/ivc_champva/v1/forms/status_updates', params: invalid_payload
        expect(response.body).to include('error')
      end
    end
  end
end