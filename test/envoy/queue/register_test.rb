require_relative '../../test_helper'

describe Envoy::Queue::Register do
  before do
    @register = described_class.new 2

    @message_1 = Envoy::Message.new SecureRandom.uuid, SecureRandom.uuid, {}
    @message_2 = Envoy::Message.new SecureRandom.uuid, SecureRandom.uuid, {}
    @message_3 = Envoy::Message.new SecureRandom.uuid, SecureRandom.uuid, {}
  end

  describe 'when a message is added' do
    before do
      @register.add @message_1
    end

    it 'has a free size of 1' do
      @register.free.must_equal 1
    end
  end

  describe 'when a two messages are added' do
    before do
      @register.add @message_1, @message_2
    end

    it 'has a free size of 0' do
      @register.free.must_equal 0
    end

    it 'can find both messages by id' do
      @register[@message_1.id].must_equal @message_1
      @register[@message_2.id].must_equal @message_2
    end
  end

  describe 'when a three messages are added' do
    before do
      @register.add @message_1, @message_2, @message_3
    end

    it 'has a free size of 0' do
      @register.free.must_equal 0
    end

    it 'can find all three messages by id' do
      @register[@message_1.id].must_equal @message_1
      @register[@message_2.id].must_equal @message_2
      @register[@message_3.id].must_equal @message_3
    end
  end

  describe 'when two messages are added and one is removed' do
    before do
      @register.add @message_1
      @register.add @message_2
      @register.remove @message_1.id
    end

    it 'has a free size of 1' do
      @register.free.must_equal 1
    end

    it 'cannot find the removed message by id' do
      @register[@message_1.id].must_be_nil
    end

    it 'can find the unremoved message by id' do
      @register[@message_2.id].must_equal @message_2
    end
  end
end
