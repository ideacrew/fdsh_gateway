# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/person_cv3'

RSpec.describe Fdsh::Ssa::H3::TransformPersonToSsaRequest, dbclean: :after_each do
  include_context "person hash for cv3"

  let(:person_entity) { AcaEntities::People::Person.new(person_params)}

  before do
    @result = subject.call(person_entity)
    @request = @result.success
  end

  it 'converts the family' do
    expect(@result).to be_success
    expect(@request.is_a?(AcaEntities::Fdsh::Ssa::H3::SSACompositeRequest)).to be_truthy
  end
end