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
    
  end
end