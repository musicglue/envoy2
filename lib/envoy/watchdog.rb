module Envoy
  class Watchdog
    include Celluloid
    include Celluloid::Notifications

    trap_exit :actor_died

    def initialize(sqs_id:, message_topics:, worker:, heartbeat_interval: 5)
      @sqs_id = sqs_id
      @message_topics = message_topics
      @worker = worker
      @heartbeat_interval = heartbeat_interval

      link @worker
      subscribe @worker.success_topic, :worker_succeeded
    end

    def process
      @timer = every(@heartbeat_interval) do
        publish @message_topics.heartbeat, @sqs_id
      end

      @worker_running = true
      @worker.async.process_for_watchdog

      loop do
        sleep 0.5
        @worker_running &&= current_actor.alive?
        break unless @worker_running
      end

      stop_heartbeat
      @worker.terminate if @worker.alive?
    end

    def actor_died _, _
      stop_heartbeat
      publish(@message_topics.failure, @sqs_id) rescue Celluloid::DeadActorError
      @worker_running = false
    end

    def worker_succeeded _topic
      stop_heartbeat
      unlink @worker
      publish(@message_topics.success, @sqs_id) rescue Celluloid::DeadActorError
      @worker_running = false
    end

    private

    def stop_heartbeat
      @timer.cancel if @timer
    end
  end
end
