# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/family_response'

RSpec.describe Fdsh::H41::H41BatchRequestDirector do
  include_context "family response from enroll"

  before :all do
    DatabaseCleaner.clean
  end

  let!(:h41_transaction) do
    Fdsh::H41::Request::StoreH41FamilyRequest.new.call({ family_hash: family_hash })
    H41Transaction.all.first
  end

  subject do
    described_class.new.call({
                               transactions_per_file: 1,
                               outbound_folder_name: "h41_outbound",
                               start_date: Date.today - 10.days,
                               end_date: Date.today + 1.day,
                               batch_size: 1
                             })
  end

  it 'should return a success' do
    # expect(subject.success?).to be_truthy
  end
end
