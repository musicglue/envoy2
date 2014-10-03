require_relative '../test_helper'

describe Envoy::Watchdog do
  before do
    @message_id = SecureRandom.uuid
    @queue = Envoy::StubQueue.new 'test1'
  end

  def create_message
    described_class.new(
      id: @message_id,
      message_topics: @queue.message_topics,
      worker: @worker,
      heartbeat_interval: 0.5)
  end

  describe 'the worker assigned to the message succeeds' do
    class FastSucceedingWorker
      include Envoy::Worker

      def process
      end
    end

    before do
      @worker = FastSucceedingWorker.new
      @message = create_message
    end

    it 'publishes a message_processed event' do
      @message.process
      sleep 0.2
      @queue.acknowledged_messages.must_include @message_id
    end
  end

  describe 'the worker assigned to the message fails' do
    class FastFailingWorker
      include Envoy::Worker
    end

    before do
      @worker = FastFailingWorker.new
      @message = create_message
    end

    it 'publishes a message_failed event' do
      @message.process
      sleep 0.2
      @queue.unacknowledged_messages.must_include @message_id
    end
  end

  describe 'the worker assigned to the message succeeds after a heartbeat' do
    class SlowSucceedingWorker
      include Envoy::Worker

      def process
        sleep 1
      end
    end

    before do
      @worker = SlowSucceedingWorker.new
      @message = create_message
    end

    it 'publishes a message_heartbeat event' do
      @message.process
      sleep 1.2
      @queue.message_heartbeats.must_include @message_id
      @queue.acknowledged_messages.must_include @message_id
    end
  end
end
