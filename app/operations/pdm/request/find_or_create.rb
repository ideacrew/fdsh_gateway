# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

# module Operations
module Pdm
  module Request
    # Upsert a PdmManifest with associated PdmRequest.
    # The operation will first search for a record matching :type, :assistance_year,
    # and :file_generated parameters and update it with the :request parameter.
    # If a match isn't found, it will create a new record with the :correlation_id
    # and :activity parameters
    class FindOrCreate
      include Dry::Monads[:try, :result, :do]

      # @param [Hash] opts The options to create application object
      # @option opts [Hash] :request
      # @option opts [Hash] :manifest
      # @option opts [Boolean] :file_generated
      # @return [Dry::Monads::Result]
      def call(request, manifest, file_generated=false)
        values = yield validate_params({request: request, manifest: manifest})
        instance = yield find_or_create_request(request, manifest, file_generated)
        result = yield persist(instance)
        Success(instance)
      end

      private

      def validate_params(params)
        errors = []
        result_manifest = ::AcaEntities::Pdm::Contracts::ManifestContract.new.call(params[:manifest])
        result_request = ::AcaEntities::Pdm::Contracts::RequestContract.new.call(params[:request])
        # result_applicant = ::AcaEntities::MagiMedicaid::Contracts::ApplicantContract.new.call(params[:request][:request_payload])
        errors << result_manifest.errors if result_manifest.errors.present?
        errors << result_request.errors if result_request.errors.present?
        # errors << result_applicant.errors if result_applicant.errors.present?
        errors.empty? ? Success(params) : Failure(errors)
      end

      # rubocop:disable Style/MultilineBlockChain
      def find_or_create_request(request, manifest_params, file_generated)
        manifest_search = ::PdmManifest.where(type: manifest_params[:type],
                              assistance_year: manifest_params[:assistance_year],
                              file_generated: file_generated)
        manifest = if manifest_search.empty?
                     ::PdmManifest.new(manifest_params.merge({file_generated: file_generated}))
                   else
                    manifest_search.first
                   end
        manifest.update(manifest_params)
        
        request_search = manifest.pdm_requests.where(:subject_id => request[:subject_id],
                                          :request_type => request[:request_type], 
                                          :document_identifier => request[:document_identifier]) 
        
        result = if request_search.present?
          request_search.first.update(request)
          request_search.first
        else
          manifest.pdm_requests << ::PdmRequest.new(request)
          manifest.pdm_requests.last
        end

        Success(result)

        # store applicant payload as JSON string
        # request[:request_payload] = request[:request_payload].to_json
        # manifest.pdm_requests << ::PdmRequest.new(request)
        # Success(manifest)
      end

      # rubocop:enable Style/MultilineBlockChain

      def persist(instance)
        if instance.save
          Success(instance)
        else
          Failure("Unable to persist Manifest #{instance.id}")
        end
      end

    end
  end
end