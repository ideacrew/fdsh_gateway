# frozen_string_literal: true

module Publishers
  module FdshGateway
    class Tax1095asPublisher
      include ::EventSource::Publisher[amqp: 'fdsh_gateway.tax1095as']

      register_event 'notice_requested'
    end
  end
end
