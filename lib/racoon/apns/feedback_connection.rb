# Racoon - A distributed APNs provider
# Copyright (c) 2011, Jeremy Tregunna, All Rights Reserved.
#
# This module contains the code that connects to the feedback service.

module Racoon
  module APNS
    class FeedbackConnection < Connection
      def initialize(pem, host = 'feedback.push.apple.com', port = 2196, pass = nil)
        @pem, @host, @port, @pass = pem, host, port, pass
      end

      def read
        records ||= []
        while record = @ssl.read(38)
          records << parse_tuple(record)
        end
        records
      end

      private

      def parse_tuple(data)
        feedback = data.unpack("N1n1H*")
        { :feedback_at => Time.at(feedback[0]), :length => feedback[1], :device_token => feedback[2] }
      end
    end
  end
end