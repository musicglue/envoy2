module Envoy
  module Worker
    extend ActiveSupport::Concern

    included do
      include Celluloid
      include Celluloid::Notifications
      include Envoy::Logging

      attr_reader :log_data, :message

      if defined?(::NewRelic)
        include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
        add_transaction_tracer :process_for_watchdog, category: :task
      end
    end

    module ClassMethods
      def middleware
        @middleware ||= []
      end
    end

    def initialize message
      @message = message

      @log_data = {
        component: self.class.to_s.underscore,
        queue: message.queue,
        message_sqs_id: message.sqs_id,
        message_id: message.id,
        message_type: message.type
      }
    end

    def logger
      Envoy::Logging
    end

    def middleware
      ::Middleware::Builder.new.tap do |stack|
        middlewares = self.class.middleware + [Envoy::Middlewares::Worker]
        middlewares.each { |m| stack.use m, self }
      end
    end

    def process
      fail NotImplementedError
    end

    def process_for_watchdog
      middleware.call
      publish success_topic
    end

    def success_topic
      "worker_succeeded_for_#{message.sqs_id}"
    end
  end
end
