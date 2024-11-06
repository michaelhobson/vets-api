# frozen_string_literal: true

module Vye
  class ClaimantVerificationSerializer < Vye::VyeSerializer
    def serializable_hash
      {
        claimant_id: @resource.claimant_id,
        delimiting_date: @resource.delimiting_date,
        enrollment_verifications: @resource.enrollment_verifications,
        verified_details: @resource.verified_details,
        payment_on_hold: @resource.payment_on_hold
      }
    end
  end
end