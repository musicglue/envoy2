module Envoy
  class Queue
    include Celluloid
    include Celluloid::Notifications
    include Envoy::Logging

    def initialize name
      @name = name
      @message_topics = Watchdog::MessageTopics.new(
        "message_processed_on_#{@name}",
        "message_failed_on_#{@name}",
        "message_heartbeat_on_#{@name}")

      @stopping = false

      subscribe @message_topics.success, :acknowledge_message
      subscribe @message_topics.failure, :unacknowledge_message
      subscribe @message_topics.heartbeat, :message_heartbeat
    end

    def acknowledge_message _topic, _id
    end

    def message_heartbeat _topic, _id
    end

    def unacknowledge_message _topic, _id
    end

    attr_reader :message_topics
  end
end
