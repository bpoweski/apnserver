$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
  

module Apnserver
  VERSION = '0.0.1'
end

require 'rubygems'
gem 'eventmachine', '>= 0.12.8'
require 'eventmachine'
require 'apnserver/payload'
require 'apnserver/notification'
require 'apnserver/protocol'
require 'apnserver/client'
require 'apnserver/server_connection'
require 'apnserver/server'
