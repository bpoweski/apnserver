require 'beanstalk-client'

module ApnServer
  class QueueServer

    attr_accessor :client, :beanstalkd_uris, :port, :feedback_callback

    def initialize(beanstalkd_uris = ["beanstalk://127.0.0.1:11300"], &feedback_blk)
      @clients = {}
      @feedback_callback = feedback_blk
      @beanstalkd_uris = beanstalkd_uris
      Config.logger = Logger.new("/dev/stdout")
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

    def handle_job(job)
      job_hash = job.ybody
      if notification = ApnServer::Notification.valid?(job_hash[:notification])
        client = get_client(job_hash[:project_name], job_hash[:certificate])
        begin
          client.connect! unless client.connected?
          client.write(notification)
          job.delete
        rescue Errno::EPIPE, OpenSSL::SSL::SSLError, Errno::ECONNRESET
          Config.logger.error "Caught Error, closing connecting and adding notification back to queue"
          client.disconnect!
          # Queue back up the notification
          job.release
          # TODO: Write a failure receipt
        rescue RuntimeError => e
          Config.logger.error "Unable to handle: #{e}"
        end
      end
    end

    def get_client(project_name, certificate)
      @clients[project_name] ||= ApnServer::Client.new(certificate)
      client = @clients[project_name]

      # If the certificate has changed, but we still are connected using the old certificate,
      # disconnect and reconnect.
      unless client.pem.eql?(certificate)
        client.disconnect!
        @clients[project_name] = ApnServer::Client.new(certificate)
        client = @clients[project_name]
      end

      client
    end
  end
end