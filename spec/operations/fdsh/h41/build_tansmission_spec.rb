# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::H41::BuildTransmission do

  subject { described_class.new }

  context 'with invalid params' do
    let(:params) do
      {
        assistance_year: Date.today.year,
        report_types: [:voided],
        allow_list: []
      }
    end

    it 'should return a failure' do
      output = subject.call(params)

      expect(output).to be_failure
      expect(output.failure).to include("invalid report type [:voided]")
    end
  end

  context 'when report types include :all ' do
    let(:params) do
      {
        assistance_year: Date.today.year,
        report_types: [:all, :corrected],
        allow_list: []
      }
    end

    let(:publish_service) do
      ::Fdsh::H41::Transmissions::Publish.new
    end

    before do
      allow(publish_service).to receive(:call).and_return(true)
      allow(subject).to receive(:publish_service).and_return(publish_service)
    end

    it 'should generate all reports' do
      output = subject.call(params)

      expect(output).to be_success
      expect(output.success[:report_types]).to eq [:original, :corrected, :void]
    end
  end

end
