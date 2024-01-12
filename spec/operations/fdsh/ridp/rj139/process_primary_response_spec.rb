# frozen_string_literal: true

require 'spec_helper'
require 'open3'

RSpec.describe Fdsh::Ridp::Rj139::ProcessPrimaryResponse do
  let(:response_body) do
    {
      ridpResponse: {
        responseMetadata: {
          responseCode: "ABCDEFGH",
          responseText: "ABCDEFGHIJKLMNOPQRSTUVWXYZA",
          tdsResponseText: "ABCDEFGHIJKLMNOPQRSTU"
        },
        sessionIdentification: "# Ik5/ 77RnhJ",
        verificationQuestionArray: [
          {
            verificationQuestionSet: {
              verificationQuestionText: "ABCDEFG",
              verificationAnswerChoiceArray: [
                {
                  verificationAnswerChoiceText: "ABCDEFGHIJKLMNOPQRSTUVWXYZABC"
                }
              ]
            }
          },
          {
            verificationQuestionSet: {
              verificationQuestionText: "ABCDEFGHIJKLMN",
              verificationAnswerChoiceArray: [
                {
                  verificationAnswerChoiceText: "ABCDEFGHIJKLMNOPQ"
                }
              ]
            }
          },
          {
            verificationQuestionSet: {
              verificationQuestionText: "ABCD",
              verificationAnswerChoiceArray: [
                {
                  verificationAnswerChoiceText: "ABCDEFGHIJKLM"
                }
              ]
            }
          },
          {
            verificationQuestionSet: {
              verificationQuestionText: "ABCDEFGHIJKLMNOP",
              verificationAnswerChoiceArray: [
                {
                  verificationAnswerChoiceText: "ABCDEFGHIJKLMNOPQRSTUVWXYZAB"
                }
              ]
            }
          },
          {
            verificationQuestionSet: {
              verificationQuestionText: "ABCDEFGHIJKLMNOPQRSTUVWXYZA",
              verificationAnswerChoiceArray: [
                {
                  verificationAnswerChoiceText: "ABCDEFG"
                }
              ]
            }
          }
        ],
        finalDecisionCode: "ACC",
        hubReferenceNumber: "ABCDEFGH"
      }
    }
  end

  context 'valid cms payload' do

    before do
      @result = described_class.new.call(response_body)
    end

    it "is successful" do
      expect(@result.success?).to be_truthy
    end

    it "result to be an Attestation object" do
      expect(@result.value!).to be_a AcaEntities::Attestations::Attestation
    end

    it "attestation should be satified" do
      expect(@result.value![:attestations][:ridp_attestation][:is_self_attested]).to eq true
    end
  end

  context 'invalid cms payload' do

    before do
      response_body[:ridpResponse].delete(:responseMetadata)
      @result = described_class.new.call(response_body)
    end

    it "is a failure" do
      expect(@result.failure?).to be_truthy
    end

  end

end