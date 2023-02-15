# frozen_string_literal: true

require 'rails_helper'

RSpec.describe H41::InsurancePolicies::PostedFamily, type: :model do
  let(:correlation_id) { 'ae321f' }
  let(:contract_holder_id) { '25458' }
  let(:family_cv) { 'family: {}' }

  let(:policy_hbx_id) { '6655644' }
  let(:assistance_year) { Date.today.year - 1.year }

  let(:insurance_policies) do
    [
      H41::InsurancePolicies::InsurancePolicy.new(
        policy_hbx_id: policy_hbx_id,
        assistance_year: assistance_year,
        aptc_csr_tax_households: aptc_csr_tax_households
      )
    ]
  end

  let(:transaction_xml) { '<xml>hello world</xml>' }
  let(:aptc_csr_tax_households) do
    [H41::InsurancePolicies::AptcCsrTaxHousehold.new(hbx_assigned_id: '5454555', transaction_xml: transaction_xml)]
  end

  let(:required_params) do
    {
      correlation_id: correlation_id,
      contract_holder_id: contract_holder_id,
      family_cv: family_cv,
      insurance_policies: insurance_policies
    }
  end

  context 'Given all required, valid params' do
    it 'should be valid, persist and findable' do
      result = described_class.new(required_params)
      expect(described_class.all.count).to eq 0
      expect(result.valid?).to be_truthy
      expect(result.save).to be_truthy
      expect(described_class.all.count).to eq 1
      expect(described_class.find(result._id).created_at).to be_present
    end
  end
end

__END__

posted_family = described_class.all.first
insurance_policy = posted_family.insurance_policies.first
aptc_csr_thh = insurance_policy.aptc_csr_tax_households.first

# ---------------------- Given Start
h41_original_transmission = H41::Transmissions::Outbound::OriginalTransmission.new({ options: {} })
h41_original_transmission.valid?
h41_original_transmission.save!

h41_corrected_transmission = H41::Transmissions::Outbound::CorrectedTransmission.new({ options: {} })
h41_corrected_transmission.valid?
h41_corrected_transmission.save!

h41_void_transmission = H41::Transmissions::Outbound::VoidTransmission.new({ options: {} })
h41_void_transmission.valid?
h41_void_transmission.save!
# ---------------------- Given End

transaction = Transmittable::Transaction.new(subject: aptc_csr_thh, status: :transmitted, transmission: h41_original_transmission)
transaction.valid?
transaction.save!

transaction1 = Transmittable::Transaction.new(subject: aptc_csr_thh, status: :transmitted, transmission: h41_corrected_transmission)
transaction1.valid?
transaction1.save!

transaction2 = Transmittable::Transaction.new(subject: aptc_csr_thh, status: :transmitted, transmission: h41_void_transmission)
transaction2.valid?
transaction2.save!

transaction3 = Transmittable::Transaction.new(subject: aptc_csr_thh, transmission: h41_corrected_transmission, status: :created, transmit_action: :blocked)
transaction3.valid?
transaction3.save!

transaction4 = Transmittable::Transaction.new(subject: aptc_csr_thh, transmission: h41_corrected_transmission, status: :created, transmit_action: :no_transmit)
transaction4.valid?
transaction4.save!

transaction5 = Transmittable::Transaction.new(subject: aptc_csr_thh, transmission: h41_corrected_transmission, status: :created, transmit_action: :transmit)
transaction5.valid?
transaction5.save!

Transmittable::Transaction.all.blocked.count
Transmittable::Transaction.all.no_transmit.count
Transmittable::Transaction.all.transmit_pending.count
Transmittable::Transaction.all.transmitted.count

H41::Transmissions::Outbound::OriginalTransmission.first.transactions.transmitted.count
H41::Transmissions::Outbound::OriginalTransmission.where(:'transactions'.exists => true).count
