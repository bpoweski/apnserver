require 'beanstalk-client'

module Racoon
  class Server
    attr_accessor :beanstalkd_uris, :feedback_callback

    def initialize(beanstalkd_uris = ["127.0.0.1:11300"], &feedback_blk)
      @beanstalks = {}
      @clients = {}
      @feedback_callback = feedback_blk
      @beanstalkd_uris = beanstalkd_uris
    end

    def beanstalk(arg)
      tube = "racoon-#{arg}"
      return @beanstalks[tube] if @beanstalks[tube]
      @beanstalks[tube] = Beanstalk::Pool.new @beanstalkd_uris
      @beanstalks[tube]
    end

    def start!
      EventMachine::run do
        EventMachine::PeriodicTimer.new(3600) do
          begin
            b = beanstalk('feedback')
            %w{watch use}.each { |s| b.send(s, "racoon-feedback") }
            b.ignore('default')
            if b.peek_ready
              item = b.reserve(1)
              handle_feedback(item)
            end
          rescue Beanstalk::TimedOut
            Config.logger.info "(Beanstalkd) Unable to secure a job, operation timed out."
          end
        end

        EventMachine::PeriodicTimer.new(1) do
          begin
            b = beanstalk('apns')
            %w{watch use}.each { |s| b.send(s, "racoon-apns") }
            b.ignore('default')
            if b.peek_ready
              item = b.reserve(1)
              handle_job item
            end
          rescue Beanstalk::TimedOut
            Config.logger.info "(Beanstalkd) Unable to secure a job, operation timed out."
          end
        end
      end
    end

    private

    # Received a notification. job is YAML encoded hash in the following format:
    # job = {
    #   :project => {
    #     :name => "Foo",
    #     :certificate => "contents of a certificate.pem"
    #   },
    #   :device_token => "0f21ab...def",
    #   :notification => notification.payload,
    #   :sandbox => true # Development environment?
    # }
    def handle_job(job)
      packet = job.ybody
      project = packet[:project]

      notification = Notification.create_from_packet(packet)

      if notification
        client = get_client(project[:name], project[:certificate], packet[:sandbox])

        begin
          p notification
          client.write(notification)

          # TODO: Listen for error responses from Apple
          job.delete
        rescue Errno::EPIPE, OpenSSL::SSL::SSLError, Errno::ECONNRESET
          Config.logger.error "Caught error, closing connection and adding notification back to queue"

          client.disconnect!

          job.release
        rescue RuntimeError => e
          Config.logger.error "Unable to handle: #{e}"

          job.delete
        end
      end
    end

    # Will be a hash with two keys:
    # :certificate and :sandbox.
    def handle_feedback(job)
      begin
        packet = job.ybody
        uri = "feedback.#{packet[:sandbox] ? 'sandbox.' : ''}push.apple.com"
        feedback_client = Racoon::FeedbackClient.new(packet[:certificate], uri)
        feedback_client.connect!
        feedback_client.read.each do |record|
          feedback_callback.call record
        end
        feedback_client.disconnect!
        job.delete
      rescue Errno::EPIPE, OpenSSL::SSL::SSLError, Errno::ECONNRESET
        Config.logger.error "(Feedback) Caught Error, closing connection"
        feedback_client.disconnect!
        job.release
      rescue RuntimeError => e
        Config.logger.error "(Feedback) Unable to handle: #{e}"
        job.delete
      end
    end

    def get_client(project_name, certificate, sandbox = false)
      uri = "gateway.#{sandbox ? 'sandbox.' : ''}push.apple.com"
      @clients[project_name] ||= Racoon::Client.new(certificate, uri)
      client = @clients[project_name]

      # If the certificate has changed, but we still are connected using the old certificate,
      # disconnect and reconnect.
      unless client.pem.eql?(certificate)
        client.disconnect! if client.connected?
        @clients[project_name] = Racoon::Client.new(certificate, uri)
        client = @clients[project_name]
      end

      client
    end

    def purge_client(job)
      project_name = job.ybody
      client = @clients[project_name]
      client.disconnect! if client
      @clients[project_name] = nil
      job.delete
    end
  end
end
