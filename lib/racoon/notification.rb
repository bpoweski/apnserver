require 'racoon/payload'
require 'base64'
require 'yajl'

module Racoon
  class Notification
    include Racoon::Payload

    attr_accessor :device_token, :alert, :badge, :sound, :custom, :send_at

    def initialize
      @send_at = Time.now
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
      [0, 0, device_token.size, device_token, 0, j.size, j].pack("ccca*cca*")
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

      header = buffer.slice!(0, 3).unpack('ccc')
      if header[0] != 0
        raise RuntimeError.new("Header of notification is invalid: #{header.inspect}")
      end

      # parse token
      notification.device_token = buffer.slice!(0, 32).unpack('a*').first

      # parse json payload
      payload_len = buffer.slice!(0, 2).unpack('CC')
      j = buffer.slice!(0, payload_len.last)
      result = Yajl::Parser.parse(j)

      ['alert', 'badge', 'sound'].each do |k|
        notification.send("#{k}=", result['aps'][k]) if result['aps'] && result['aps'][k]
      end
      result.delete('aps')
      notification.custom = result

      notification
    end
  end
end
