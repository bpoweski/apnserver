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
    def initialize(address = "tcp://*:11555", context = ZMQ::Context.new(1))
      @connections = {}
      @context = context
      @firehose = context.socket(ZMQ::PULL)
      @address = address
    end

    def start!
      EventMachine::run do
        @firehose.bind(@address)

        apns = EventMachine.spawn do |project, bytes, retries|
          uri = "gateway.#{project[:sandbox] ? 'sandbox.' : ''}push.apple.com"
          hash = project_hash(project)

          begin
            @connection[hash] ||= Racoon::APNS::Connection.new(project[:certificate], uri)

            @connection[hash].connect! unless @connection[hash].connected?
            @connection[hash].write(bytes)
          rescue Errno::EPIPE, OpenSSL::SSL::SSLError, Errno::ECONNRESET
            @connection[hash].disconnect!
            retry if (retries -= 1) > 0
          end
        end

        EventMachine::PeriodicTimer.new(0.1) do
          received_message = ZMQ::Message.new
          @firehose.recv(received_message, ZMQ::NOBLOCK)
          yaml_string = received_message.copy_out_string
          
          if yaml_string and yaml_string != ""
            packet = YAML::load(yaml_string)

            apns.notify(packet[:project], packet[:bytes], 2)
          end
        end
      end
    end

    def project_hash(project)
      Digest::SHA1.hexdigest("#{project[:name]}-#{project[:certificate]}")
    end
  end
end
