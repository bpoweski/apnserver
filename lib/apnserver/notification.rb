require 'apnserver/payload'
require 'json'

module ApnServer
  
  class Notification
    include ApnServer::Payload
    
    attr_accessor :device_token, :alert, :badge, :sound, :custom
    
    def payload
      p = Hash.new
      p[:badge] = badge if badge
      p[:alert] = alert if alert
      create_payload(p)
    end
    
    def json_payload
      p = JSON.generate(payload)
      raise PayloadInvalid.new("Payload of #{p.size} is longer than 256") if p.size > 256
      p
    end
    
    def to_bytes
      json = json_payload
      [0, 0, device_token.size, device_token, 0, json.size, json].pack("ccca*cca*")
    end
    
    def self.valid_request?(payload)
      begin
        Notification.read_notification(payload)        
        true
      rescue RuntimeError
        false
      end
    end
    
    def self.read_notification(p)
      payload = p.dup
      notification = Notification.new
      
      header = payload.slice!(0, 3).unpack('ccc')
      if header[0] != 0 || header[1] != 0 || header[2] != 32
        raise RuntimeError.new("Header of notification is invalid: #{header.inspect}")
      end
      
      notification.device_token = payload.slice!(0, 32).unpack('a*').first
      payload_len = payload.slice!(0, 2).unpack('cc')
      json = payload.slice!(0, payload_len.last)

      notification
    end
  end
end