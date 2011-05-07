# Racoon - A distributed APNs provider
# Copyright (c) 2011, Jeremy Tregunna, All Rights Reserved.
#
# APNs payload data

module Racoon
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