# frozen_string_literal: true

module ClaimsApi
  class DocumentServiceBase < ServiceBase
    ##
    # Generate form body to upload a document
    #
    # @return {parameters, file}
    # rubocop:disable Metrics/ParameterLists
    def generate_upload_body(claim_id:, system_name:, doc_type:, pdf_path:, file_name:, birls_file_number:,
                             participant_id:, tracked_item_ids:)

      payload = {}

      data = build_body(claim_id:, system_name:, doc_type:, file_name:, participant_id:,
                        file_number: birls_file_number, tracked_item_ids:)

      fn = Tempfile.new('params')
      File.write(fn, data.to_json)
      payload[:parameters] = Faraday::UploadIO.new(fn, 'application/json')
      payload[:file] = Faraday::UploadIO.new(pdf_path.to_s, 'application/pdf')
      payload
    end
    # rubocop:enable Metrics/ParameterLists

    def compact_veteran_name(first_name, last_name)
      [first_name, last_name].compact_blank.join('_')
    end

    def build_file_name(veteran_name:, identifier:, suffix:)
      "#{[veteran_name, identifier, suffix].compact_blank.join('_')}.pdf"
    end

    private

    def build_body(options = {})
      data = {
        systemName: options[:system_name],
        docType: options[:doc_type],
        fileName: options[:file_name],
        trackedItemIds: options[:tracked_item_ids].presence || []
      }
      data[:claimId] = options[:claim_id] unless options[:claim_id].nil?
      data[:participantId] = options[:participant_id] unless options[:participant_id].nil?
      data[:fileNumber] = options[:file_number] unless options[:file_number].nil?
      { data: }
    end
  end
end