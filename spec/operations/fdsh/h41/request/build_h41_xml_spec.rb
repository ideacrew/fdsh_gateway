require 'spec_helper'
require 'shared_examples/family_response'

RSpec.describe Fdsh::H41::Request::BuildH41Xml do
  include_context "family response from enroll"

  before :all do
    DatabaseCleaner.clean
  end

  let(:family) { AcaEntities::Families::Family.new(family_hash) }
  let(:household) { family.households.first }
  let(:agreement) { household.insurance_agreements.first }
  let(:insurance_policy) { agreement.insurance_policies.first }
  let(:tax_household) { insurace_policy.aptc_csr_tax_households.first }

  let(:params) do
    {  
      family: family,
      insurance_policy: insurance_policy,
      agreement: agreement,
      tax_household: insurance_policy.aptc_csr_tax_households.first
    }
  end

  subject do
    described_class.new.call(params)
  end

  it 'should return a success' do
    expect(subject.success?).to be_truthy
  end
end
