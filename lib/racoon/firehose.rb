# Racoon - A distributed APNs provider
# Copyright (c) 2011, Jeremy Tregunna, All Rights Reserved.
#
# This module contains the firehose which is responsible for maintaining all the open
# connections to Apple, and sending data over the right ones.

require 'digest/sha1'
require 'eventmachine'
require 'ffi-rzmq'

module Racoon
  class Firehose
    def initialize(address = "tcp://*:11555", context = ZMQ::Context.new(1), &feedback_callback)
      @connections = {}
      @context = context
      @firehose = context.socket(ZMQ::PULL)
      @address = address
      @feedback_callback = feedback_callback
    end

    def start!
      EventMachine::run do
        @firehose.bind(@address)

        EventMachine::PeriodicTimer.new(28800) do
          @connections.each_pair do |key, data|
            begin
              uri = "gateway.#{project[:sandbox] ? 'sandbox.' : ''}push.apple.com"
              feedback = Racoon::APNS::FeedbackConnection.new(data[:certificate], uri)
              feedback.connect!
              feedback.read.each do |record|
                @feedback_callback.call(record) if @feedback_callback
              end
            rescue Errno::EPIPE, OpenSSL::SSL::SSLError, Errno::ECONNRESET
              feedback.disconnect!
            end
          end
        end

        EventMachine::PeriodicTimer.new(0.1) do
          received_message = ZMQ::Message.new
          @firehose.recv(received_message, ZMQ::NOBLOCK)
          yaml_string = received_message.copy_out_string
          
          if yaml_string and yaml_string != ""
            packet = YAML::load(yaml_string)

            apns(packet[:project], packet[:bytes])
          end
        end
      end
    end

    def apns(project, bytes, retries=2)
      uri = "gateway.#{project[:sandbox] ? 'sandbox.' : ''}push.apple.com"
      hash = Digest::SHA1.hexdigest("#{project[:name]}-#{project[:certificate]}")

      begin
        connection = Racoon::APNS::Connection.new(project[:certificate], uri)
        @connections[hash] ||= { :connection => connection, :certificate => project[:certificate], :sandbox => project[:sandbox] }

        connection.connect! unless connection.connected?
        connection.write(bytes)
      rescue Errno::EPIPE, OpenSSL::SSL::SSLError, Errno::ECONNRESET
        connection.disconnect!
        retry if (retries -= 1) > 0
      end
    end
  end
end
