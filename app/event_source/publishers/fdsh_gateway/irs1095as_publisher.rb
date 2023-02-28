# frozen_string_literal: true

module Publishers
  module FdshGateway
    class Irs1095asPublisher
      include ::EventSource::Publisher[amqp: 'fdsh_gateway.irs1095as']

      register_event 'initial_notice_requested'
      register_event 'void_notice_requested'
      register_event 'corrected_notice_requested'
    end
  end
end
