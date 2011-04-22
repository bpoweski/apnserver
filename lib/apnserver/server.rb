require 'beanstalk-client'
require 'yajl'
require 'base64'

module ApnServer
  class Server

    attr_accessor :beanstalkd_uris, :feedback_callback

    def initialize(beanstalkd_uris = ["127.0.0.1:11300"], &feedback_blk)
      @clients = {}
      @feedback_callback = feedback_blk
      @beanstalkd_uris = beanstalkd_uris
    end

    def beanstalk
      @@beanstalk ||= Beanstalk::Pool.new @beanstalkd_uris
    end

    def start!
      EventMachine::run do
        EventMachine::PeriodicTimer.new(28800) do
          begin
            @feedback_client = nil # Until we pull in DB support
            @feedback_client.connect! unless @feedback_client.connected?
            @feedback_client.read.each do |record|
              feedback_callback.call record
            end
            @feedback_client.disconnect!
          rescue Errno::EPIPE, OpenSSL::SSL::SSLError, Errno::ECONNRESET
            Config.logger.error "(Feedback) Caught Error, closing connection"
            @feedback_client.disconnect!
          rescue RuntimeError => e
            Config.logger.error "(Feedback) Unable to handle: #{e}"
          end
        end

        EventMachine::PeriodicTimer.new(1) do
          begin
            if beanstalk.peek_ready
              item = beanstalk.reserve(1)
              handle_job item
            end
          rescue Beanstalk::TimedOut
            Config.logger.info "(Beanstalkd) Unable to secure a job, operation timed out."
          end
        end
      end
    end

    private

    # Jobs should be posted as a YAML encoded hash in the following format:
    #
    #   @job = { 
    #     :project => { 
    #       :name => "example",
    #       :certificate => "/path/to/pem.pem",
    #     },
    #     :sandbox => Rails.env.development?,
    #     :notification => notification.json_payload, 
    #     :device_token => notification.device_token, # Base64 encoded
    #   }
    #
    # Receipt UUID's may be added in later.

    def handle_job(job)
      packet = job.ybody
      project = packet[:project]

      # Build new notification object from our hash
      apn_data = packet[:notification][:aps]

      notification = Notification.new
      notification.device_token = Base64.decode64(packet[:device_token])

      notification.badge = apn_data[:badge] if apn_data.has_key?(:badge)
      notification.alert = apn_data[:alert] if apn_data.has_key?(:alert)
      notification.sound = apn_data[:sound] if apn_data.has_key?(:sound)
      notification.custom = apn_data[:custom] if apn_data.has_key?(:custom)

      # TODO skip this file read unless necessary
      certificate_data = File.read(project[:certificate])

      if notification
        client = get_client(project[:name], certificate_data, packet[:sandbox])
        begin
          Config.logger.debug "Connection already open" if client.connected?
          client.connect! unless client.connected?
          client.write(notification)
          job.delete
          Config.logger.info "Notification should've been deleted, keeping socket open."
          # TODO: Find the receipt and update the sent_at property.
          #if receipt = PushLog[packet[:receipt_uuid]]
          #  receipt.sent_at = Time.now.to_i.to_s
          #  receipt.save
          #end
        rescue Errno::EPIPE, OpenSSL::SSL::SSLError, Errno::ECONNRESET
          Config.logger.error "Caught Error, closing connecting and adding notification back to queue."
          client.disconnect!
          # Queue back up the notification
          job.release
          Config.logger.info "Notification should've been released."
        rescue RuntimeError => e
          Config.logger.error "Unable to handle: #{e}"
          # TODO: Find the receipt and write the failed_at property.
          #if receipt = PushLog[packet[:receipt_uuid]]
          #  receipt.failed_at = Time.now.to_i.to_s
          #  receipt.save
          #end
          job.delete
        end
      else
        Config.logger.error "Unable to create payload, deleting message."
        job.delete
      end
    rescue Exception => e
        Config.logger.error "#{$!} -- Printing Backtrace:\n #{e.backtrace.join "\n"}, deleting job"
        job.delete
    end

    def get_client(project_name, certificate, sandbox = false)
      uri = "gateway.#{sandbox ? 'sandbox.' : ''}push.apple.com"
      @clients[project_name] ||= ApnServer::Client.new(certificate, uri)
      client = @clients[project_name]

      # If the certificate has changed, but we still are connected using the old certificate,
      # disconnect and reconnect.
      unless client.pem.eql?(certificate)
        client.disconnect! if client.connected?
        @clients[project_name] = ApnServer::Client.new(certificate, uri)
        client = @clients[project_name]
      end

      client
    end
  end
end
