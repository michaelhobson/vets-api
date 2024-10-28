# frozen_string_literal: true

require 'swagger_helper'
require Rails.root.join('spec', 'rswag_override.rb').to_s
require_relative '../../../support/swagger_shared_components/v0'

RSpec.describe 'PDF Generator 21-22a', openapi_spec: 'modules/representation_management/app/swagger/v0/swagger.json',
                                       type: :request do
  before do
    create(:accredited_organization,
           id: SwaggerSharedComponents::V0.representative[:organization_id],
           name: 'Veterans Organization')
    create(:accredited_individual,
           id: SwaggerSharedComponents::V0.representative[:id])
  end

  path '/representation_management/v0/pdf_generator2122a' do
    post('Generate a PDF for form 21-22a') do
      tags 'PDF Generation'
      consumes 'application/json'
      produces 'application/pdf'
      operationId 'createPdfForm2122a'

      parameter SwaggerSharedComponents::V0.body_examples[:pdf_generator2122a_parameter]

      response '200', 'PDF generated successfully' do
        let(:pdf_generator2122a) do
          SwaggerSharedComponents::V0.body_examples[:pdf_generator2122a]
        end
        run_test!
      end

      response '422', 'unprocessable entity response' do
        let(:pdf_generator2122a) do
          params = SwaggerSharedComponents::V0.body_examples[:pdf_generator2122a]
          params[:veteran][:name].delete(:first)
          params
        end
        schema '$ref' => '#/components/schemas/Errors'
        run_test!
      end
    end
  end
end
