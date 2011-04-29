# Racoon - A distributed APNs provider
# Copyright (c) 2011, Jeremy Tregunna, All Rights Reserved.
#
# This module contains the firehose which is responsible for maintaining all the open
# connections to Apple, and sending data over the right ones.

require 'digest/sha1'
require 'zmqmachine'
require 'yaml'

module Racoon
  class Firehose
    attr_accessor :connections, :feedback_callback

    def initialize(reactor, address = ZM::Address.new('*', 11555, :tcp), &feedback_callback)
      @connections = {}
      @reactor = reactor
      @address = address
      @feedback_callback = feedback_callback
    end

    def on_attach(socket)
      socket.bind(@address)
    end

    def on_readable(socket, messages)
      messages.each do |message|
        packet = YAML::load(message.copy_out_string)
        apns(packet[:project], packet[:bytes])
      end
    end

    private

    def apns(project, bytes, retries=2)
      uri = "gateway.#{project[:sandbox] ? 'sandbox.' : ''}push.apple.com"
      hash = Digest::SHA1.hexdigest("#{project[:name]}-#{project[:certificate]}")

      begin
        @connections[hash] ||= { :connection => Racoon::APNS::Connection.new(project[:certificate], uri),
                                 :certificate => project[:certificate],
                                 :sandbox => project[:sandbox] }
        connection = @connections[hash][:connection]

        connection.connect! unless connection.connected?
        connection.write(bytes)
      rescue Errno::EPIPE, OpenSSL::SSL::SSLError, Errno::ECONNRESET
        connection.disconnect!
        retry if (retries -= 1) > 0
      end
    end
  end
end
