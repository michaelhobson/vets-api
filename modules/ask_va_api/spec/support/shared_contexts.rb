# frozen_string_literal: true

RSpec.shared_context 'shared data' do
  let(:inquiry_params) do
    {
      question: 'fasfdas',
      phone_number: '3039751100',
      email_address: 'test@test.com',
      contact_preference: 'Email',
      preferred_name: 'Submitter',
      pronouns: { he_him_his: true },
      is_veteran_deceased: false,
      about_the_veteran: {
        first: 'Joseph',
        last: 'New',
        suffix: 'Sr.',
        social_or_service_num: { ssn: '123456799' },
        date_of_birth: '2000-01-01'
      },
      their_vre_information: false,
      is_military_base: false,
      postal_code: '80122',
      family_members_location_of_residence: 'Alabama',
      about_the_family_member: {
        first: 'James',
        last: 'New',
        suffix: 'Jr.',
        date_of_birth: '2000-01-01'
      },
      their_relationship_to_veteran: 'CHILD',
      is_question_about_veteran_or_someone_else: 'Veteran',
      relationship_to_veteran: "I'm a family member of a Veteran",
      select_category: 'Health care',
      select_topic: 'Audiology and hearing aids',
      who_is_your_question_about: 'Someone else',
      about_yourself: { social_or_service_num: {} },
      on_base_outside_us: false,
      address: { military_address: {} },
      state_or_residency: {},
      category_id: '73524deb-d864-eb11-bb24-000d3a579c45',
      topic_id: 'c0da1728-d91f-ed11-b83c-001dd8069009',
      subtopic_id: '',
      updated_in_review: '',
      search_location_input: '',
      get_location_in_progress: false,
      current_user_location: '',
      get_location_error: false,
      selected_facility: nil,
      review_page_view: { open_chapters: [] },
      files: [{ file_name: nil, file_content: nil }],
      school_obj: {},
      controller: 'ask_va_api/v0/inquiries',
      action: 'unauth_create',
      inquiry: {
        question: 'fasfdas',
        phone_number: '3039751100',
        email_address: 'test@test.com',
        contact_preference: 'Email',
        preferred_name: 'Submitter',
        pronouns: { he_him_his: true },
        is_veteran_deceased: false,
        about_the_veteran: {
          first: 'Joseph',
          last: 'New',
          suffix: 'Sr.',
          social_or_service_num: { ssn: '123456799' },
          date_of_birth: '2000-01-01'
        },
        their_vre_information: false,
        is_military_base: false,
        postal_code: '80122',
        family_members_location_of_residence: 'Alabama',
        about_the_family_member: {
          first: 'James',
          last: 'New',
          suffix: 'Jr.',
          date_of_birth: '2000-01-01'
        },
        their_relationship_to_veteran: 'CHILD',
        is_question_about_veteran_or_someone_else: 'Veteran',
        relationship_to_veteran: "I'm a family member of a Veteran",
        select_category: 'Health care',
        select_topic: 'Audiology and hearing aids',
        who_is_your_question_about: 'Someone else',
        about_yourself: { social_or_service_num: {} },
        on_base_outside_us: false,
        address: { military_address: {} },
        state_or_residency: {},
        category_id: '73524deb-d864-eb11-bb24-000d3a579c45',
        topic_id: 'c0da1728-d91f-ed11-b83c-001dd8069009',
        subtopic_id: '',
        updated_in_review: '',
        search_location_input: '',
        get_location_in_progress: false,
        current_user_location: '',
        get_location_error: false,
        selected_facility: nil,
        review_page_view: { open_chapters: [] },
        files: [{ file_name: nil, file_content: nil }],
        school_obj: {}
      }
    }
  end
  let(:translated_payload) do
    { AreYouTheDependent: false,
      AttachmentPresent: false,
      BranchOfService: nil,
      CaregiverZipCode: nil,
      ContactMethod: 722_310_000,
      DependantDOB: '2000-01-01',
      DependantFirstName: 'James',
      DependantLastName: 'New',
      DependantMiddleName: nil,
      DependantRelationship: nil,
      InquiryAbout: 722_310_001,
      InquiryCategory: '73524deb-d864-eb11-bb24-000d3a579c45',
      InquirySource: '722310000',
      InquirySubtopic: '',
      InquirySummary: nil,
      InquiryTopic: 'c0da1728-d91f-ed11-b83c-001dd8069009',
      InquiryType: nil,
      IsVeteranDeceased: false,
      LevelOfAuthentication: 722_310_001,
      MedicalCenter: nil,
      SchoolObj: { City: nil,
                   InstitutionName: nil,
                   SchoolFacilityCode: nil,
                   StateAbbreviation: nil,
                   RegionalOffice: nil },
      SubmitterQuestion: 'fasfdas',
      SubmitterStateOfSchool: { Name: nil, StateCode: nil },
      SubmitterStateProperty: { Name: nil, StateCode: nil },
      SubmitterStateOfResidency: { Name: nil, StateCode: nil },
      SubmitterZipCodeOfResidency: '80122',
      UntrustedFlag: nil,
      VeteranRelationship: 722_310_007,
      WhoWasTheirCounselor: nil,
      ListOfAttachments: nil,
      SubmitterProfile: { FirstName: nil,
                          MiddleName: nil,
                          LastName: nil,
                          PreferredName: 'Submitter',
                          Suffix: nil,
                          Gender: nil,
                          Pronouns: 'he/him/his',
                          Country: { Name: nil, CountryCode: nil },
                          Street: nil,
                          City: nil,
                          State: { Name: nil, StateCode: nil },
                          ZipCode: '80122',
                          Province: nil,
                          DateOfBirth: nil,
                          BusinessPhone: nil,
                          PersonalPhone: '3039751100',
                          BusinessEmail: nil,
                          PersonalEmail: 'test@test.com',
                          SchoolState: nil,
                          SchoolFacilityCode: nil,
                          SchoolId: nil,
                          BranchOfService: nil,
                          SSN: nil,
                          EDIPI: '123',
                          ICN: '234',
                          ServiceNumber: nil,
                          ClaimNumber: nil,
                          VeteranServiceStateDate: nil,
                          VeteranServiceEndDate: nil },
      VeteranProfile: { FirstName: 'Joseph',
                        MiddleName: nil,
                        LastName: 'New',
                        PreferredName: nil,
                        Suffix: 722_310_001,
                        Country: nil,
                        Street: nil,
                        City: nil,
                        State: { Name: nil, StateCode: nil },
                        ZipCode: nil,
                        DateOfBirth: '2000-01-01',
                        BranchOfService: nil,
                        SSN: '123456799',
                        ServiceNumber: nil,
                        ClaimNumber: nil,
                        VeteranServiceStateDate: nil,
                        VeteranServiceEndDate: nil } }
  end
end
