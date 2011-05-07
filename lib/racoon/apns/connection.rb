# Racoon - A distributed APNs provider
# Copyright (c) 2011, Jeremy Tregunna, All Rights Reserved.
#
# This module contains the connection to the APNs service.

require 'openssl'
require 'socket'

module Racoon
  module APNS
    class Connection
      attr_accessor :pem, :host, :port, :password

      def initialize(pem, host = 'gateway.push.apple.com', port = 2195, pass = nil)
        @pem, @host, @port, @password = pem, host, port, pass
      end

      def connect!
        raise "Your certificate is not set." unless self.pem

        @context      = OpenSSL::SSL::SSLContext.new
        @context.cert = OpenSSL::X509::Certificate.new(self.pem)
        @context.key  = OpenSSL::PKey::RSA.new(self.pem, self.password)

        @sock         = TCPSocket.new(self.host, self.port.to_i)
        @ssl          = OpenSSL::SSL::SSLSocket.new(@sock, @context)
        @ssl.connect

        return @sock, @ssl
      end

      def disconnect!
        @ssl.close
        @sock.close
        @ssl = nil
        @sock = nil
      end

      def read
        errors ||= []
        while error = @ssl.read(6)
          errors << parse_tuple(error)
        end
        errors
      end

      def write(bytes)
        if host.include? "sandbox"
          notification = Notification.parse(bytes)
          Config.logger.debug "#{Time.now} [#{host}:#{port}] Device: #{notification.device_token.unpack('H*')} sending #{notification.json_payload}"
        end
        @ssl.write(notification.to_bytes)
      end

      def connected?
        @ssl
      end

      private

      def parse_tuple(data)
        packet = data.unpack("c1c1N1")
        { :command => packet[0], :status => packet[1], :identifier => packet[2] }
      end
    end
  end
end
