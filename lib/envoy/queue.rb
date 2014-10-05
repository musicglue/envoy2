module Envoy
  class Queue
    include Celluloid
    include Celluloid::Notifications
    include Envoy::Logging

    def initialize name, sqs, config
      @name = name
      @sqs = sqs
      @config = config.get_queue name

      @message_topics = Watchdog::MessageTopics.new(
        "message_processed_on_#{@name}",
        "message_failed_on_#{@name}",
        "message_heartbeat_on_#{@name}")

      @stopped = true
      @register = Register.new @config.message_concurrency
      @router = Router.new @config

      @log_data = {
        component: 'queue',
        name: @name
      }

      subscribe @message_topics.success, :acknowledge_message
      subscribe @message_topics.failure, :unacknowledge_message
      subscribe @message_topics.heartbeat, :message_heartbeat
    end

    attr_reader :message_topics

    def acknowledge_message _topic, sqs_id
      info @log_data.merge(
        at: 'acknowledge_message',
        sqs_id: sqs_id)

      @sqs.delete_message @name, @register[sqs_id].receipt_handle
    end

    def message_heartbeat _topic, sqs_id
      info @log_data.merge(
        at: 'message_heartbeat',
        sqs_id: sqs_id)

      @sqs.extend_message_invisibility(
        @name,
        @register[sqs_id].receipt_handle,
        @config.message_heartbeat_interval)
    end

    def start
      return unless @stopped
      @stopped = false

      loop do
        @stopped ||= !current_actor.alive?
        break if @stopped
        dequeue_messages
        sleep sleep_time
      end

      debug @log_data.merge(at: 'exiting')
    end

    def stop
      @stopped = true
    end

    def unacknowledge_message _topic, sqs_id
      warn @log_data.merge(
        at: 'unacknowledge_message',
        sqs_id: sqs_id)
    end

    private

    def dequeue_messages
      if @register.free == 0
        @messages_dequeued = 0
      else
        messages = @sqs.receive_messages @name, @register.free
        @messages_dequeued = messages.count

        messages.each do |message|
          next unless (worker_class = @router.route(message))

          @register.add message

          debug @log_data.merge(
            at: 'routing',
            sqs_id: message.sqs_id,
            worker: worker_class.to_s.underscore)

          Watchdog.new(
            sqs_id: message.sqs_id,
            message_topics: @message_topics,
            worker: worker_class.new(message),
            heartbeat_interval: @config.message_heartbeat_interval).async.process
        end
      end

      debug @log_data.merge(
        at: 'dequeue_messages',
        messages_dequeued: @messages_dequeued
      ) if @messages_dequeued > 0
    end

    def sleep_time
      @messages_dequeued == 0 ? 1 : 0.1
    end
  end
end
