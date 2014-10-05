module Envoy
  class Message
    def initialize sqs_id, receipt_handle, queue, payload
      @sqs_id = sqs_id
      @receipt_handle = receipt_handle
      @queue = queue
      @payload = payload

      @headers = @payload[:headers] || @payload[:header]
      @body = @payload[:body]
    end

    attr_reader :sqs_id, :receipt_handle, :queue, :headers, :body

    def id
      @headers[:id]
    end

    def type
      @headers[:type]
    end

    def to_h
      @payload
    end
  end
end
