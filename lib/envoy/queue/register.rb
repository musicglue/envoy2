module Envoy
  class Queue
    class Register
      # it's possible that we might end up receiving more messages
      # than there are free slots, so the 'size' of the register
      # is just a soft limit. it will still accept every message.
      def initialize size
        @size = size
        @messages = []
      end

      def add *messages
        @messages.push *messages
      end

      def free
        [@size - @messages.count, 0].max
      end

      def[] sqs_id
        @messages.find { |message| message.sqs_id == sqs_id }
      end

      def remove sqs_id
        @messages.delete_if do |message|
          message.sqs_id == sqs_id
        end
      end
    end
  end
end
