# frozen_string_literal: true

class EvidenceSubmission < ApplicationRecord
  has_kms_key
  has_encrypted :template_metadata, key: :kms_key, **lockbox_options

end
