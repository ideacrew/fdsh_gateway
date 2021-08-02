# frozen_string_literal: true

require 'rails_helper'
require 'pry'

RSpec.describe Fdsh::Vlp::H92::HandleInitialVerificationRequest, "given:
  - a correlation id
  - a payload
  - the primary determination request is successful
  - contains a valid soap body in the response
  - the response can be processed" do

  let(:correlation_id) { "SOME GENERATED CORRELATION ID" }
  let(:payload) { { message: "A REQUEST PAYLOAD" } }

  let(:mock_request_operation) do
    instance_double(
      ::Fdsh::Vlp::H92::RequestInitialVerification
    )
  end

  let(:mock_response_operation) do
    instance_double(
      ::Fdsh::Vlp::H92::ProcessInitialVerificationResponse
    )
  end

  let(:mock_soap_operation) do
    instance_double(
      ::Soap::RemoveSoapEnvelope
    )
  end

  let(:request_operation_result) do
    Dry::Monads::Result::Success.call(
      instance_double(
        Faraday::Response,
        body: "SOME RESPONSE BODY"
      )
    )
  end

  let(:response_operation_result) do
    Dry::Monads::Result::Success.call(
      { message: "THE PROCESSED RESPONSE OBJECT" }
    )
  end

  let(:soap_operation_result) do
    Dry::Monads::Result::Success.call(
      "SOME EXTRACTED SOAP BODY"
    )
  end

  before :each do
    allow(::Fdsh::Vlp::H92::RequestInitialVerification).to receive(:new).and_return(
      mock_request_operation
    )
    allow(::Fdsh::Vlp::H92::ProcessInitialVerificationResponse).to receive(:new).and_return(
      mock_response_operation
    )
    allow(::Soap::RemoveSoapEnvelope).to receive(:new).and_return(
      mock_soap_operation
    )
    allow(mock_request_operation).to receive(:call).with(
      payload
    ).and_return(request_operation_result)
    allow(mock_soap_operation).to receive(:call).with(
      "SOME RESPONSE BODY"
    ).and_return(soap_operation_result)
    allow(mock_response_operation).to receive(:call).with(
      "SOME EXTRACTED SOAP BODY"
    ).and_return(response_operation_result)
  end

  subject do
    described_class.new.call({
                               correlation_id: correlation_id,
                               payload: payload
                             })
  end

  it "is successful" do
    expect(subject.success?).to be_truthy
  end
end

# RSpec.describe Fdsh::Vlp::H92::HandleInitialVerificationRequest do

#   let(:payload) do
#     {
#       correlation_id: "1105835",
#       payload: request
#     }
#   end

#   let(:request) do

#     {:hbx_id=>"1105835",
#      :person_name=>{:first_name=>"SHAMII",
#      :middle_name=>nil,
#      :last_name=>"KULKARNIII",
#      :name_sfx=>nil,
#      :name_pfx=>nil,
#      :full_name=>"SHAMII KULKARNIII",
#      :alternate_name=>nil},
#      :person_demographics=>{:ssn=>nil,
#      :no_ssn=>true,
#      :gender=>"female",
#      :dob=>Date.new(1990, 01, 01),
#      :date_of_death=>nil,
#      :dob_check=>false,
#      :is_incarcerated=>false,
#      :ethnicity=>["", "", "", "", "", "", ""],
#      :race=>nil,
#      :tribal_id=>nil,
#      :language_code=>"en"},
#      :person_health=>{:is_tobacco_user=>"unknown",
#      :is_physically_disabled=>nil},
#      :no_dc_address=>false,
#      :no_dc_address_reason=>nil,
#      :is_homeless=>false,
#      :is_temporarily_out_of_state=>false,
#      :age_off_excluded=>false,
#      :is_applying_for_assistance=>nil,
#      :is_active=>true,
#      :is_disabled=>nil,
#      :person_relationships=>[],
#      :consumer_role=>{:five_year_bar=>false,
#      :requested_coverage_start_date=> DateTTime.now,
#      :aasm_state=>"dhs_pending",
#      :is_applicant=>true,
#      :birth_location=>nil,
#      :marital_status=>nil,
#      :is_active=>true,
#      :is_applying_coverage=>true,
#      :bookmark_url=>"https://dev-enroll.cme.openhbx.org/families/home",
#      :admin_bookmark_url=>"/insured/families/home",
#      :contact_method=>"Paper and Electronic communications",
#      :language_preference=>"English",
#      :is_state_resident=>nil,
#      :identity_validation=>"valid",
#      :identity_update_reason=>"Document in EnrollApp",
#      :application_validation=>"outstanding",
#      :application_update_reason=>nil,
#      :identity_rejected=>false,
#      :application_rejected=>false,
#      :vlp_documents=>[{:title=>"untitled",
#      :creator=>"dchl",
#      :subject=>"Other (With Alien Number)",
#      :description=>"Notice of Action",
#      :publisher=>"dchl",
#      :contributor=>nil,
#      :date=>nil,
#      :type=>"text",
#      :format=>"application/octet-stream",
#      :identifier=>nil,
#      :source=>"enroll_system",
#      :language=>"en",
#      :relation=>nil,
#      :coverage=>nil,
#      :rights=>nil,
#      :tags=>[],
#      :size=>nil,
#      :doc_identifier=>nil,
#      :alien_number=>"900000002",
#      :i94_number=>nil,
#      :visa_number=>nil,
#      :passport_number=>nil,
#      :sevis_id=>nil,
#      :naturalization_number=>nil,
#      :receipt_number=>nil,
#      :citizenship_number=>nil,
#      :card_number=>nil,
#      :country_of_citizenship=>"India",
#      :expiration_date=> Date.new(2019, 01, 02),
#      :issuing_country=>nil}],
#      :lawful_presence_determination=>{:vlp_verified_at=>nil,
#      :vlp_authority=>nil,
#      :vlp_document_id=>nil,
#      :citizen_status=>"alien_lawfully_present",
#      :citizenship_result=>nil,
#      :qualified_non_citizenship_result=>nil,
#      :aasm_state=>"verification_pending"},
#      :local_residency_requests=>[{:requested_at=>DateTime.now, :body=>"jhskl"}]},
#      :resident_role=>nil,
#      :individual_market_transitions=>[],
#      :verification_types=>[],
#      :broker_role=>nil,
#      :user=>{:approved=>true,
#      :email=>"shami.test@gmail.com",
#      :oim_id=>"shami.test@gmail.com",
#      :hint=>true,
#      :identity_confirmed_token=>nil,
#      :identity_final_decision_code=>nil,
#      :identity_final_decision_transaction_id=>nil,
#      :identity_response_code=>nil,
#      :identity_response_description_text=>nil,
#      :identity_verified_date=>nil,
#      :idp_uuid=>nil,
#      :idp_verified=>true,
#      :last_portal_visited=>"/insured/consumer_role/search",
#      :preferred_language=>"en",
#      :profile_type=>nil,
#      :roles=>["consumer"]},
#      :addresses=>[{:has_fixed_address=>true,
#      :kind=>"home",
#      :address_1=>"9 ocean ave",
#      :address_2=>"",
#      :address_3=>"",
#      :city=>"newport",
#      :county=>"Androscoggin",
#      :state=>"ME",
#      :zip=>"04210",
#      :country_name=>"United States of America"}],
#      :emails=>[{:kind=>"home",
#      :address=>"shami.test@gmail.com"}],
#      :phones=>[],
#      :documents=>[],
#      :timestamp=>{:created_at=>DateTime.now,
#      :modified_at=> DateTime.now}
#     }

#     subject do
#       described_class.new.call({
#                                  correlation_id: correlation_id,
#                                  payload: payload
#                                })
#     end

#     it "is successful" do
#       binding.irb
#       expect(subject.success?).to be_truthy
#     end
#   end
# end
