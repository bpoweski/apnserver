# Racoon - A distributed APNs provider
# Copyright (c) 2011, Jeremy Tregunna, All Rights Reserved.
#
# Configuration settings.

module Racoon
  class Config
    class << self
      attr_accessor :logger
    end
  end

  Config.logger = Logger.new("/dev/null")
end