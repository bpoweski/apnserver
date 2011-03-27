require 'apnserver/payload'
require 'base64'
require 'yajl'

module ApnServer
  class Config
    class << self
      attr_accessor :host, :port, :pem, :password, :logger
    end
  end

  Config.logger = Logger.new("/dev/null")

  class Notification
    include ApnServer::Payload

    attr_accessor :device_token, :alert, :badge, :sound, :custom

    def payload
      p = Hash.new
      [:badge, :alert, :sound, :custom].each do |k|
        p[k] = send(k) if send(k)
      end
      create_payload(p)
    end

    def json_payload
      j = Yajl::Encoder.encode(payload)
      raise PayloadInvalid.new("The payload is larger than allowed: #{j.length}") if j.size > 256
      j
    end

    def push
      if Config.pem.nil?
        socket = TCPSocket.new(Config.host || 'localhost', Config.port.to_i || 22195)
        socket.write(to_bytes)
        socket.close
      else
        client = ApnServer::Client.new(Config.pem, Config.host || 'gateway.push.apple.com', Config.port.to_i || 2195)
        client.connect!
        client.write(self)
        client.disconnect!
      end
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
