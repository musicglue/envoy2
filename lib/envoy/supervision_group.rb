module Envoy
  class SupervisionGroup
    def initialize config, sqs
      @config = config
      @group = Celluloid::SupervisionGroup.new
      @sqs = sqs
    end

    def start
      add_custom_actors @config.celluloid.actors
      add_queues
    end

    def stop
      @group.actors.each do |actor|
        actor.stop if actor.respond_to? :stop
      end
    end

    private

    def add_custom_actors actors
      actors.each do |actor|
        @group.supervise(actor).async.run
      end
    end

    def add_queues
      queues = [@config.dead_letter_queue, @config.queues].flatten.compact

      queues.each do |queue|
        @group.supervise(Envoy::Queue, queue.name, @sqs, @config).async.start
      end
    end
  end
end
