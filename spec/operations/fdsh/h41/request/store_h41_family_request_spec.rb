require 'spec_helper'
require 'shared_examples/family_response'

RSpec.describe Fdsh::H41::Request::StoreH41FamilyRequest do
  include_context "family response from enroll"

  before :all do
    DatabaseCleaner.clean
  end

  subject do
    described_class.new.call({family_hash: family_hash})
  end

  it 'should return a success' do
    expect(subject.success?).to be_truthy
  end

  it 'should persist h41 transaction' do
    expect(H41Transaction.count).to eq 1

    h41_transaction = H41Transaction.first 
    expect(h41_transaction.activities).to be_present 
    expect(h41_transaction.aptc_csr_tax_households).to be_present 
  end
end
