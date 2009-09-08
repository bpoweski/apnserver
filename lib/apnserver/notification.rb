module ApnServer
  
  class Notification
    attr_accessor :device_token, :alert, :badge, :sound, :custom
    
    def to_bytes
      payload = '{"aps":{"alert":"' + alert + '"}}'
      [0, 0, device_token.size, device_token, 0, payload.size, payload].pack("ccca*cca*")
    end
    
  end
end