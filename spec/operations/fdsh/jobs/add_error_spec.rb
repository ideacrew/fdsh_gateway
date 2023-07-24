# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/ssa_transmittable'

RSpec.describe Fdsh::Jobs::AddError, dbclean: :after_each do
  include_context "ssa transmittable job transmission transaction"
  subject { described_class.new }

  context 'sending valid params' do
    before do
      @result = subject.call({ transmittable_objects: { transaction: transaction, transmission: transmission, job: job }, key: :test_key,
                               message: "A TEST MESSAGE" })
    end

    it 'should return a success with all required params' do
      expect(@result.success?).to be_truthy
      expect(transaction.transmittable_errors.first.key).to eq :test_key
      expect(transmission.transmittable_errors.first.key).to eq :test_key
      expect(job.transmittable_errors.first.key).to eq :test_key
    end
  end
end