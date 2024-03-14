require 'shared_examples/family_cv3_secondary_ridp'

RSpec.describe Fdsh::Ridp::H139::TransformFamilyToSecondaryDetermination do
  include_context "family cv3 with secondary ridp attestation"


  subject { described_class.new }

  let(:family) { AcaEntities::Families::Family.new(family_hash) }


  context 'sending valid params' do
    it 'should return secondary request' do

      result = subject.call(family)

      expect(result.success?).to be_truthy
      expect(result.success).to be_a(AcaEntities::Fdsh::Ridp::H139::SecondaryRequest)
    end
  end

  context 'sending invalid params' do
    context 'when DHS Reference Number is not present' do

      let(:second_request) do
        {
          SessionIdentification: "347567asghfjgshfg",
          VerificationAnswerSet: {
            VerificationAnswers: [{
              VerificationQuestionNumber: 1,
              VerificatonAnswer: 1
            },
                                    {
                                      VerificationQuestionNumber: 2,
                                      VerificatonAnswer: 1
                                    },
                                    {
                                      VerificationQuestionNumber: 3,
                                      VerificatonAnswer: 2
                                    }]
          }
        }
      end

      it 'should return a failure with missing key' do
        result = subject.call(family)
        expect(result.failure.to_h).to eq({:DSHReferenceNumber=>["is missing"]})
      end
    end
  end
end
