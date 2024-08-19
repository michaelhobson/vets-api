# frozen_string_literal: true

module ClaimsApi
  module V2
    class ClaimValidator
      def initialize(bgs_claim, lighthouse_claim, request_icn, target_veteran)
        @bgs_claim = bgs_claim
        @lighthouse_claim = lighthouse_claim
        @request_icn = request_icn
        @target_vet_participant_id = target_veteran.participant_id
      end

      def validate
        if not_valid_claim_with_id_with_icn?
          raise ::Common::Exceptions::ResourceNotFound.new(
            detail: 'Invalid claim ID for the veteran identified.'
          )
        end
      end

      private

      def not_valid_claim_with_id_with_icn?
        if @bgs_claim&.dig(:benefit_claim_details_dto).present?
          clm_prtcpnt_vet_id = @bgs_claim&.dig(:benefit_claim_details_dto, :ptcpnt_vet_id)
          clm_prtcpnt_clmnt_id = @bgs_claim&.dig(:benefit_claim_details_dto, :ptcpnt_clmant_id)
        end

        veteran_icn = if @lighthouse_claim.present? && @lighthouse_claim['veteran_icn'].present?
                        @lighthouse_claim['veteran_icn']
                      end

        if clm_prtcpnt_cannot_access_claim?(clm_prtcpnt_vet_id, clm_prtcpnt_clmnt_id) && veteran_icn != @request_icn
          return true
        end

        false
      end

      def clm_prtcpnt_cannot_access_claim?(clm_prtcpnt_vet_id, clm_prtcpnt_clmnt_id)
        return true unless clm_prtcpnt_vet_id && clm_prtcpnt_clmnt_id

        # if either of these is false then we have a match, return that false and can show the record
        clm_prtcpnt_vet_id != @target_vet_participant_id && clm_prtcpnt_clmnt_id != @target_vet_participant_id
      end
    end
  end
end