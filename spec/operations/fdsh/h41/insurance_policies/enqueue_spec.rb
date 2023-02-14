# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/family_response'

RSpec.describe Fdsh::H41::InsurancePolicies::Enqueue do
  subject { described_class.new.call(input_params) }

  before :all do
    DatabaseCleaner.clean
  end

  describe '#call' do
    include_context "family response from enroll"

    context 'with valid input params' do
      let(:input_params) do
        {
          correlation_id: 'correlation_id',
          family: family_hash
        }
      end

      it 'returns a success with a message' do
        expect(
          subject.success
        ).to eq('Successfully processed event: edi_gateway.insurance_policies.posted')
      end
    end

    context 'with invalid input params' do
      context 'bad input family Cv' do
        let(:input_params) do
          {
            correlation_id: 'correlation_id',
            family: family_hash.merge(hbx_id: nil)
          }
        end

        it 'returns failure with errors' do
          expect(
            subject.failure
          ).to eq({ hbx_id: ['must be filled'] })
        end
      end
    end
  end
end
