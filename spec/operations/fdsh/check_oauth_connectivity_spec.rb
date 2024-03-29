# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::CheckOauthConnectivity, "given invalid JSON" do

  subject do
    described_class.new.call({})
  end

  context "valid token" do
    before(:each) do
      stub_request(:post, "https://impl.hub.cms.gov/auth/oauth/v2/token")
        .with(
          body: { "client_id" => nil, "client_secret" => nil, "grant_type" => "client_credentials" },
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Content-Type' => 'application/x-www-form-urlencoded',
            'User-Agent' => 'Faraday v1.4.3'
          }
        )
        .to_return(status: 200,
                   body: "{\r\n  \"access_token\":\"3487583567384567384568\",\r\n  \"token_type\":\"Bearer\",\r\n  \"expires_in\":1800}",
                   headers: {})

      stub_request(:post, "https://impl.hub.cms.gov/Imp1/HubConnectivityServiceRest")
        .with(
          body: "{\"hubConnectivityRequest\":{}}",
          headers: {
            'Accept' => 'application/json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => 'Bearer 3487583567384567384568',
            'Content-Type' => 'application/json',
            'User-Agent' => 'Faraday v1.4.3'
          }
        )
        .to_return(status: 200, body: "", headers: {})
    end

    it "should succeed" do
      expect(subject.success?).to be_truthy
      expect(subject.failure).to be_falsey
    end
  end

  context "invalid token" do
    before(:each) do
      stub_request(:post, "https://impl.hub.cms.gov/auth/oauth/v2/token")
        .with(
          body: { "client_id" => nil, "client_secret" => nil, "grant_type" => "client_credentials" },
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Content-Type' => 'application/x-www-form-urlencoded',
            'User-Agent' => 'Faraday v1.4.3'
          }
        )
        .to_return(status: 200, body: "{\r\n  \"error\":\"invalid_request\",\r\n  \"error_description\":\"Missing\"\r\n}", headers: {})
    end

    it "should fail" do
      expect(subject.success?).to be_falsey
      expect(subject.failure).to be_truthy
    end
  end

  context 'xml response' do

    before(:each) do
      stub_const('ENV', 'TOKEN_HOST' => 'https://impl.hub.cms.gov/HubConnectivityServiceRest')
      stub_request(:post, "https://impl.hub.cms.gov/HubConnectivityServiceRest/auth/oauth/v2/token")
        .with(
          body: { "client_id" => nil, "client_secret" => nil, "grant_type" => "client_credentials" },
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Content-Type' => 'application/x-www-form-urlencoded',
            'User-Agent' => 'Faraday v1.4.3'
          }
        )
        .to_return(status: 500, body: '<?xml version="1.0" encoding="UTF-8"?>
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
          <soapenv:Body>
              <soapenv:Fault>
                  <faultcode>soapenv:Server</faultcode>
                  <faultstring>Policy Falsified</faultstring>
                  <faultactor>https://impl.hub.cms.gov/Imp1/VerifySSACompositeService</faultactor>
                  <detail>
                      <l7:policyResult
                          status="Service Not Found.  The request may have been sent to an invalid URL"
                          xmlns:l7="http://www.layer7tech.com/ws/policy/fault"/>
                  </detail>
              </soapenv:Fault>
          </soapenv:Body>
      </soapenv:Envelope>', headers: {})
    end
    it "should fail" do

      expect(subject.success?).to be_falsey
      expect(subject.failure).to be_truthy
    end

    it "should return the failure message" do
      expect(subject.failure).to eq "Non JSON response for JWT request"
    end

  end
end

