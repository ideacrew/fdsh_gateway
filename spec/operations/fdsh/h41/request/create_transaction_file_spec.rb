# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/family_response'

RSpec.describe Fdsh::H41::Request::CreateTransactionFile do
  include_context "family response from enroll"

  before :all do
    DatabaseCleaner.clean
  end

  subject do
    described_class.new.call({family_payload: [family_hash]})
  end

  it 'should return a success monad' do
    expect(subject.success?).to be_truthy
  end
end