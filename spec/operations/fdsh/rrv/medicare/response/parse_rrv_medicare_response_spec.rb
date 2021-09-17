# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::Rrv::Medicare::Response::ParseRrvMedicareResponse do

  let(:file_path) { "#{Rails.root}/spec/reference/rrv_medicare_response.zip" }

  subject do
    described_class.new.call(file_path)
  end

  it "success" do
    expect(subject.success?).to be_truthy
  end
end