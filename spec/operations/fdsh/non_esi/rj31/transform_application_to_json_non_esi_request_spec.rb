# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/application_cv3'

RSpec.describe Fdsh::NonEsi::Rj31::TransformApplicationToJsonNonEsiRequest, dbclean: :after_each do
  include_context "application hash for cv3"

  it 'converts the application hash for non esi mec hub call' do
    result = subject.call(application_params.to_json)
    expect(result).to be_success
    applicant = result.success[:verifyNonESIMECRequest][:individualRequestArray].first
    expect(applicant[:personSurName]).to eq application_params[:applicants][0][:name][:last_name]
    expect(applicant[:personGivenName]).to eq application_params[:applicants][0][:name][:first_name]
  end
end