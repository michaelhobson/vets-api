# frozen_string_literal: true

require 'prawn/table'

module AppealsApi
  module PdfConstruction
    module HigherLevelReview::V2
      class Structure
        MAX_NUMBER_OF_ISSUES_ON_MAIN_FORM = 13

        def initialize(higher_level_review)
          @higher_level_review = higher_level_review
        end

        # rubocop:disable Metrics/MethodLength
        def form_fill
          options = {
            # Section I: Vet's ID
            # Veteran name is filled out through autosize text box, not pdf fields
            form_fields.first_three_ssn => form_data.first_three_ssn,
            form_fields.second_two_ssn => form_data.second_two_ssn,
            form_fields.last_four_ssn => form_data.last_four_ssn,
            form_fields.file_number => form_data.file_number,
            form_fields.birth_month => form_data.birth_mm,
            form_fields.birth_day => form_data.birth_dd,
            form_fields.birth_year => form_data.birth_yyyy,
            form_fields.insurance_policy_number => form_data.insurance_policy_number,
            form_fields.mailing_address_street => 'USE ADDRESS ON FILE',
            form_fields.mailing_address_unit_number => '',
            form_fields.mailing_address_city => '',
            form_fields.mailing_address_state => '',
            form_fields.mailing_address_country => '',
            form_fields.mailing_address_zip_first_5 => '',
            form_fields.mailing_address_zip_last_4 => '',
            form_fields.veteran_homeless => form_data.veteran_homeless,
            form_fields.veteran_phone_area_code => form_data.veteran_phone_area_code,
            form_fields.veteran_phone_prefix => form_data.veteran_phone_prefix,
            form_fields.veteran_phone_line_number => form_data.veteran_phone_line_number,
            form_fields.veteran_phone_international_number => form_data.veteran_phone_international_number,
            form_fields.veteran_email => form_data.veteran_email,

            # Section II: Claimant's ID
            # NOT YET SUPPORTED

            # Section III: Benefit Type
            form_fields.benefit_type(0) => form_data.benefit_type('education'),
            form_fields.benefit_type(1) => form_data.benefit_type('nca'),
            form_fields.benefit_type(2) => form_data.benefit_type('vha'),
            form_fields.benefit_type(3) => form_data.benefit_type('insurance'),
            form_fields.benefit_type(4) => form_data.benefit_type('loan_guaranty'),
            form_fields.benefit_type(5) => form_data.benefit_type('fiduciary'),
            form_fields.benefit_type(6) => form_data.benefit_type('readiness_and_employment'),
            form_fields.benefit_type(7) => form_data.benefit_type('pension_survivors_benefits'),
            form_fields.benefit_type(8) => form_data.benefit_type('compensation'),

            # Section IV: Optional Informal Conference
            form_fields.informal_conference => form_data.informal_conference,
            form_fields.conference_8_to_12 => form_data.informal_conference_time('veteran', '800-1200 ET'),
            form_fields.conference_12_to_1630 => form_data.informal_conference_time('veteran', '1200-1630 ET'),
            form_fields.conference_rep_8_to_12 => form_data.informal_conference_time('representative', '800-1200 ET'),
            form_fields.conference_rep_12_to_1630 => form_data.informal_conference_time('representative',
                                                                                        '1200-1630 ET'),
            # Rep name should be filled with autosize text boxes, not pdf fields
            # TODO: Rep detail fields

            # Section V: SOC/SSOC Opt-In
            form_fields.sso_ssoc_opt_in => form_data.soc_opt_in,

            # Section VI: Issues (allows 13 in fields)
            # Dates filled via fill_contestable_issues!, below. Issue text is filled out through autosize text boxes.

            # Section VII: Cert & Sig
            form_fields.signature => form_data.signature,
            form_fields.date_signed_month => form_data.date_signed_mm,
            form_fields.date_signed_day => form_data.date_signed_dd,
            form_fields.date_signed_year => form_data.date_signed_yyyy

            # Section VIII: Authorized Rep Sig
            # NOT YET SUPPORTED
          }

          fill_contestable_issues!(options)
        end
        # rubocop:enable Metrics/MethodLength

        def insert_overlaid_pages(form_fill_path)
          form_fill_path
        end

        def add_additional_pages
          return unless additional_pages?

          @additional_pages_pdf ||= Prawn::Document.new(skip_page_creation: true)

          # TODO: Create a contestable issues table similar to NOD's extra issues table

          @additional_pages_pdf
        end

        def final_page_adjustments
          # no-op
        end

        def form_title
          '200996_v2'
        end

        def stamp(stamped_pdf_path)
          CentralMail::DatestampPdf.new(stamped_pdf_path).run(
            text: "API.VA.GOV #{Time.zone.now.utc.strftime('%Y-%m-%d %H:%M%Z')}",
            x: 5,
            y: 5,
            text_only: true
          )
        end

        private

        attr_accessor :higher_level_review

        def form_fields
          @form_fields ||= HigherLevelReview::V2::FormFields.new
        end

        def form_data
          @form_data ||= HigherLevelReview::V2::FormData.new(higher_level_review)
        end

        def additional_pages?
          form_data.contestable_issues.count > MAX_NUMBER_OF_ISSUES_ON_MAIN_FORM
        end

        def fill_contestable_issues!(options)
          form_issues = form_data.contestable_issues.take(MAX_NUMBER_OF_ISSUES_ON_MAIN_FORM)
          form_issues.each_with_index do |issue, index|
            date_fields = form_fields.issue_decision_date_fields(index)
            date = Date.parse(issue['attributes']['decisionDate'])
            options[date_fields[:month]] = date.strftime '%m'
            options[date_fields[:day]] = date.strftime '%d'
            options[date_fields[:year]] = date.strftime '%Y'
          end
          options
        end
      end
    end
  end
end
