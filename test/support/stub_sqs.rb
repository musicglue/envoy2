class StubSqs
  def initialize
    @queues = Hash.new { [] }
    # @queue_arns = {}
    # @queue_urls = {}
  end

  attr_reader :queues

  def delete_message queue_url, receipt_handle
    @queues[queue_url].delete_if do |message|
      message.receipt_handle == receipt_handle
    end
  end

  def extend_message_invisibility _queue_url, _receipt_handle, _visibility_timeout
  end

  # def get_queue_arn queue_url
  #   queue_arns[queue_url]
  # end

  # def get_queue_url queue_name
  #   queue_urls[queue_name]
  # end

  def receive_messages queue_url, maximum = 10
    @queues[queue_url][0...maximum]
  end

  def enqueue_message queue_url, message
    @queues[queue_url] << message
  end
end
