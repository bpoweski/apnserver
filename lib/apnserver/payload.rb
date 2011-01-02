module ApnServer
  module Payload
    PayloadInvalid = Class.new(RuntimeError)

    def create_payload(payload)
      case payload
        when String then { :aps => { :alert =>  payload } }
        when Hash then create_payload_from_hash(payload)
      end
    end

    def create_payload_from_hash(payload)
      custom = payload.delete(:custom)
      aps = {:aps => payload }
      aps.merge!(custom) if custom
      aps
    end
  end
end