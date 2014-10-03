require 'aws-sdk-core'
require 'celluloid'
require 'middleware'
require 'nokogiri'
require 'securerandom'

require 'envoy/version'
require 'envoy/logging'
require 'envoy/configuration'
require 'envoy/queue'
require 'envoy/worker'
require 'envoy/watchdog/message_topics'
require 'envoy/watchdog'

module Envoy
  module_function

  def config
    @config ||= Configuration.new
  end

  def configure
    yield config
  end

  def start
    return if @running
    @running = true

    setup_logger
    config.validate!

    Celluloid.start
  end

  def stop
    return unless @running
    @running = false

    Celluloid.shutdown
  end

  def setup_logger
    Celluloid.logger = Logger.new STDOUT
    Celluloid.logger.level = Rails.logger.level
    Celluloid.logger.formatter = Rails.logger.formatter
  end
end
