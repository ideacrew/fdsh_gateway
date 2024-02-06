# frozen_string_literal: true

module Publishers
  module FdshGateway
    # The Irs1095asPublisher class is responsible for publishing events related to IRS 1095A forms.
    # It includes the EventSource::Publisher module to enable event publishing.
    # It registers three events: 'initial_notice_requested', 'void_notice_requested', and 'corrected_notice_requested'.
    class Irs1095asPublisher
      include ::EventSource::Publisher[amqp: 'fdsh_gateway.irs1095as']

      register_event 'initial_notice_requested'
      register_event 'void_notice_requested'
      register_event 'corrected_notice_requested'
    end
  end
end
