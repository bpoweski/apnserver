$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
  

module Apnserver
  VERSION = '0.0.1'
end

require 'eventmachine'
require 'apnserver/protocol'
require 'apnserver/payload'
require 'apnserver/notification'
require 'apnserver/server'