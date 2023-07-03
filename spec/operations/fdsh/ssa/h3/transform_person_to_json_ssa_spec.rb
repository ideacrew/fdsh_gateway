# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/person_cv3'

RSpec.describe Fdsh::Ssa::H3::TransformPersonToJsonSsa, dbclean: :after_each do
  include_context "person hash for cv3"

  it 'converts the Ssa hash for cms' do
    result = subject.call(person_params.to_json)
    expect(result).to be_success
    person = result.success[:ssaCompositeRequest][:ssaCompositeIndividualRequestArray].first
    expect(person[:personSurName]).to eq person_params[:person_name][:last_name]
  end
end