module Racoon
  class Config
    class << self
      attr_accessor :logger
    end
  end

  Config.logger = Logger.new("/dev/null")
end