# Racoon - A distributed APNs provider
# Copyright (c) 2011, Jeremy Tregunna, All Rights Reserved.
#
# This module contains the class that represents notifications and all their details.

require 'racoon/payload'
require 'base64'
require 'yajl'

module Racoon
  class Notification
    include Racoon::Payload

    attr_accessor :identifier, :expiry, :device_token, :alert, :badge, :sound, :custom, :expiry

    def initialize
      @expiry = 0
    end

    def payload
      p = Hash.new
      [:badge, :alert, :sound, :custom].each do |k|
        r = send(k)
        p[k] = r if r
      end
      create_payload(p)
    end

    def json_payload
      j = Yajl::Encoder.encode(payload)
      raise PayloadInvalid.new("The payload is larger than allowed: #{j.length}") if j.size > 256
      j
    end

    def to_bytes
      j = json_payload
      [1, identifier, expiry.to_i, device_token.size, device_token, j.size, j].pack("cNNna*na*")
    end

    def self.valid?(p)
      begin
        Notification.parse(p)
      rescue PayloadInvalid => p
        Config.logger.error "PayloadInvalid: #{p}"
        false
      rescue RuntimeError => r
        Config.logger.error "Runtime error: #{r}"
        false
      rescue Exception => e
        Config.logger.error "Unknown error: #{e}"
        false
      end
    end

    def self.parse(p)
      buffer = p.dup
      notification = Notification.new

      header = buffer.slice!(0, 11).unpack("cNNn")
      raise RuntimeError.new("Header of notification is invalid: #{header.inspect}") if header[0] != 1

      # identifier
      notification.identifier = header[1]
      notification.expiry = header[2]

      # device token
      notification.device_token = buffer.slice!(0, 32).unpack("a*").first

      # JSON payload
      payload_len = buffer.slice!(0, 2).unpack("n")
      j = buffer.slice!(0, payload_len.last)
      result = Yajl::Parser.parse(j)

      ['alert', 'badge', 'sound'].each do |k|
        notification.send("#{k}=", result['aps'][k]) if result['aps'] && result['aps'][k]
      end
      result.delete("aps")
      notification.custom = result

      notification
    end

    def self.create_from_packet(packet)
      aps = packet[:notification][:aps]

      notification = Notification.new
      notification.identifier = packet[:identifier]
      notification.expiry = packet[:expiry] || 0
      notification.device_token = packet[:device_token]
      notification.badge = aps[:badge] if aps.has_key? :badge
      notification.alert = aps[:alert] if aps.has_key? :alert
      notification.sound = aps[:sound] if aps.has_key? :sound
      notification.custom = aps[:custom] if aps.has_key? :custom

      notification
    end
  end
end
