# frozen_string_literal: true

require 'csv'
require 'fileutils'
require_relative 'utils'

# Built in accordance with the following documentation:
# https://github.com/department-of-veterans-affairs/va.gov-team-sensitive/blob/master/platform/practices/zero-silent-failures/remediation.md
module SimpleFormsApi
  module S3
    class SubmissionArchiveBuilder < Utils
      def initialize(**options) # rubocop:disable Lint/MissingSuper
        defaults = default_options.merge(options)
        hydrate_submission_data(defaults[:benefits_intake_uuid]) unless valid_submission_data?(defaults)
        assign_instance_variables(defaults)
      rescue => e
        handle_error('SubmissionArchiveBuilder initialization failed', e)
      end

      def run
        FileUtils.mkdir_p(temp_directory_path)
        process_submission_files
        temp_directory_path
      rescue => e
        handle_error("Failed building submission: #{benefits_intake_uuid}", e)
      end

      private

      attr_reader :attachments, :benefits_intake_uuid, :file_path, :include_json_archive, :include_manifest,
                  :include_text_archive, :metadata, :submission

      def default_options
        {
          attachments: nil,           # The confirmation codes of any attachments which were originally submitted
          benefits_intake_uuid: nil,  # The UUID returned from the Benefits Intake API upon original submission
          file_path: nil,             # The local path where the submission PDF is stored
          include_json_archive: true, # Include the form data as a JSON object
          include_manifest: true,     # Include a CSV file containing manifest data
          include_text_archive: true, # Include the form data as a text file
          metadata: nil,              # Data appended to the original submission headers
          submission: nil             # The FormSubmission object representing the original data payload submitted
        }
      end

      def valid_submission_data?(data)
        data[:submission] && data[:file_path] && data[:attachments] && data[:metadata]
      end

      def process_submission_files
        write_pdf
        write_as_json_archive if include_json_archive
        write_as_text_archive if include_text_archive
        write_attachments unless attachments && attachments.empty?
        write_manifest if include_manifest
        write_metadata
      rescue => e
        handle_error('Error during submission file processing', e)
      end

      def write_pdf
        write_tempfile(submission_pdf_filename, File.read(file_path))
      end

      def write_as_json_archive
        write_tempfile('form_json_archive.json', JSON.pretty_generate(form_data_hash))
      end

      def write_as_text_archive
        write_tempfile('form_text_archive.txt', form_data_hash.to_s)
      end

      def write_metadata
        write_tempfile('metadata.json', metadata.to_json)
      end

      def write_attachments
        log_info("Processing #{attachments.count} attachments")
        attachments.each_with_index { |guid, i| process_attachment(i + 1, guid) }
      rescue => e
        handle_error('Error during attachments processing', e)
      end

      def process_attachment(attachment_number, guid)
        log_info("Processing attachment ##{attachment_number}: #{guid}")
        attachment = PersistentAttachment.find_by(guid:).to_pdf
        raise "Attachment not found: #{guid}" unless attachment

        write_tempfile("attachment_#{attachment_number}.pdf", attachment)
      rescue => e
        handle_error("Failed processing attachment #{attachment_number} (#{guid})", e)
      end

      def write_manifest
        file_name = "submission_#{benefits_intake_uuid}_#{submission.created_at}_manifest.csv"
        manifest_path = File.join(temp_directory_path, file_name)

        CSV.open(manifest_path, 'wb') do |csv|
          csv << ['Submission DateTime', 'Form Type', 'VA.gov ID', 'Veteran ID', 'First Name', 'Last Name']
          csv << [
            submission.created_at,
            form_data_hash['form_number'],
            benefits_intake_uuid,
            metadata['fileNumber'],
            metadata['veteranFirstName'],
            metadata['veteranLastName']
          ]
        end
      rescue => e
        handle_error("Failed writing manifest for submission: #{benefits_intake_uuid}", e)
      end

      def write_tempfile(file_name, payload)
        File.write("#{temp_directory_path}#{file_name}", payload)
      rescue => e
        handle_error("Failed writing file #{file_name} for submission: #{benefits_intake_uuid}", e)
      end

      def hydrate_submission_data(benefits_intake_uuid)
        built_submission = SubmissionBuilder.new(benefits_intake_uuid:)
        @file_path = built_submission.file_path
        @submission = built_submission.submission
        @benefits_intake_uuid = @submission&.benefits_intake_uuid
        @attachments = built_submission.attachments || []
        @metadata = built_submission.metadata
      end

      def form_data_hash
        @form_data_hash ||= JSON.parse(submission.form_data)
      end

      def submission_pdf_filename
        @submission_pdf_filename ||= "form_#{form_data_hash['form_number']}.pdf"
      end
    end
  end
end
