# frozen_string_literal: true

module Subscribers
  module Fdsh
    # Receive response from FDSH requests
    class RidpServiceSubscriber
      include ::EventSource::Subscriber[http: '/RIDPService']

      subscribe(:on_RIDPService) do |body, status, headers|
        # Sequence of steps that are executed as single operation
        # puts "triggered --> on_primary_request block -- #{body} --  #{status} -- #{headers}"

        # correlation_id = headers["CorrelationID"]

        if status[:value] == 200
          # Call transform operation

          # Op will determine primary or secondary response type, route appropriately and return result here
          _response =
            Operations::Fdsh::Ridp::H139::ProcessResponse.call(
              { headers: headers, body: body }
            )

          # response = Operations::Fdsh::Ridp::H139::GeneratePrimaryRequest.call(body)
          # response = Operations::Fdsh::Ridp::H139::GenerateSecondaryRequest.call(body)

          # response = Operations::Fdsh::Ridp::H139::ProcessPrimaryResponse.call(body)
          # response = Operations::Fdsh::Ridp::H139::ProcessSecondaryResponse.call(body)

          # if response.success?
          # call operation that publishes for Enroll
          # else
          # call operation that sends error to Enroll
          # end
        else
          logger.error 'Subscribers::Fdsh::ResponseSubscriber: on_RIDPService error'
        end
      rescue StandardError => e
        logger.error "Subscribers::Fdsh::ResponseSubscriber: on_RIDPService error backtrace: #{e.backtrace}"
      end
    end
  end
end
