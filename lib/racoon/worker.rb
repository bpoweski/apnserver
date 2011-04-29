# Racoon - A distributed APNs provider
# Copyright (c) 2011, Jeremy Tregunna, All Rights Reserved.
#
# This module contains the worker which processes notifications before sending them off
# down to the firehose.

require 'beanstalk-client'
require 'eventmachine'
require 'ffi-rzmq'

module Racoon
  class Worker
    def initialize(beanstalk_uris, address = "tcp://*:11555", context = ZMQ::Context.new(1))
      @beanstalk_uris = beanstalk_uris
      @context = context
      @firehose = context.socket(ZMQ::PUSH)
      @address = address
      # First packet, send something silly, the firehose ignores it
      @send_batch = true
    end
    
    def start!
      EventMachine::run do
        @firehose.connect(@address)

        if @send_batch
          @send_batch = false
          @firehose.send_string("")
        end

        EventMachine::PeriodicTimer.new(0.5) do
          begin
            if beanstalk.peek_ready
              job = beanstalk.reserve(1)
              process job
            end
          rescue Beanstalk::TimedOut
            Config.logger.info "[Beanstalk] Unable to secure job, operation timed out."
          end
        end
      end
    end

    private

    def beanstalk
      return @beanstalk if @beanstalk
      @beanstalk ||= Beanstalk::Pool.new(@beanstalk_uris)
      %w{use watch}.each { |s| @beanstalk.send(s, 'racoon') }
      @beanstalk.ignore('default')
      @beanstalk
    end

    # Expects json ala:
    # json = {
    #   "project":{
    #      "name":"foobar",
    #      "certificate":"...",
    #      "sandbox":false
    #   },
    #   "bytes":"..."
    # }
    def process(job)
      packet = job.ybody
      project = packet[:project]

      notification = Notification.create_from_packet(packet)

      data = { :project => project, :bytes => notification.to_bytes }
      @firehose.send_string(Yajl::Encoder.encode(data))
    end
  end
end
