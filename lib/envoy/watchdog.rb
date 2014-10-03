module Envoy
  class Watchdog
    include Celluloid
    include Celluloid::Notifications
    include Envoy::Logging

    trap_exit :actor_died

    def initialize(id:, message_topics:, worker:, heartbeat_interval: 5)
      @id = id
      @message_topics = message_topics
      @heartbeat_interval = heartbeat_interval

      @worker = worker
      @worker.success_topic = "worker_succeeded_for_#{@id}"

      link @worker
      subscribe @worker.success_topic, :worker_succeeded
    end

    def process
      @timer = every(@heartbeat_interval) do
        publish @message_topics.heartbeat, @id
      end

      @worker_running = true
      @worker.async.process_for_watchdog

      loop do
        sleep 0.5
        break unless @worker_running
      end

      @worker.terminate if @worker.alive?
    end

    def actor_died _, _
      publish @message_topics.failure, @id
      @worker_running = false
    end

    def worker_succeeded _topic
      unlink @worker
      publish @message_topics.success, @id
      @worker_running = false
    end
  end
end
