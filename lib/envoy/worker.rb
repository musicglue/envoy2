module Envoy
  module Worker
    extend ActiveSupport::Concern

    included do
      include Celluloid
      include Celluloid::Notifications
      include Envoy::Logging

      attr_accessor :success_topic

      # if defined?(::NewRelic)
      #   include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
      #   add_transaction_tracer :safely_process, category: :task
      # end
    end

    module ClassMethods
      def middleware
        @middleware ||= []
      end
    end

    def process
      fail NotImplementedError
    end

    def process_for_watchdog
      process
      publish success_topic
    end
  end
end
