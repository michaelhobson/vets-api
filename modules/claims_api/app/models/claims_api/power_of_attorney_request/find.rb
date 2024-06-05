# frozen_string_literal: true

module ClaimsApi
  class PowerOfAttorneyRequest
    module Find
      class << self
        def perform(id) # rubocop:disable Metrics/MethodLength
          participant_id, proc_id = id.split('_')

          action =
            BGSClient::Definitions::
              ManageRepresentativeService::
              ReadPoaRequestByParticipantId::
              DEFINITION

          result = begin
            BGSClient.perform_request(action) do |xml|
              xml.PtcpntId(participant_id)
            end
          rescue BGSClient::Error::BGSFault => e
            reason = e.detail.dig('MessageException', 'reason')
            reason == 'NO_RECORD_FOUND' and
              raise ::Common::Exceptions::RecordNotFound, id

            raise
          end

          poa_requests = Array.wrap(result['poaRequestRespondReturnVOList'])
          poa_request = poa_requests.find do |data|
            data['procID'] == proc_id
          end

          poa_request.nil? and
            raise ::Common::Exceptions::RecordNotFound, id

          Load.perform(poa_request)
        end
      end
    end
  end
end