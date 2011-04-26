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

        # Every minute,poll all the clients, ensuring they've been inactive for 20+ minutes.
        EventMachine::PeriodicTimer.new(60) do
          remove_clients = []

          @clients.each_pair do |project_name, packet|
            if Time.now - packet[:timestamp] >= 1200 # 20 minutes
              packet[:connection].disconnect!
              remove_clients << project_name
            end
          end

          remove_clients.each do |project_name|
            @clients[project_name] = nil
          end
        end

        EventMachine::PeriodicTimer.new(2) do
          begin
            b = beanstalk('apns')
            %w{watch use}.each { |s| b.send(s, "racoon-apns") }
            b.ignore('default')
            jobs = []
            until b.peek_ready.nil?
              item = b.reserve(1)
              jobs << item
            end
            handle_jobs jobs if jobs.count > 0
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
    def handle_jobs(jobs)
      connections = {}
      jobs.each do |job|
        packet = job.ybody
        project = packet[:project]

        client = get_client(project[:name], project[:certificate], packet[:sandbox])
        conn = client[:connection]
        connections[conn] ||= []

        notification = create_notification_from_packet(packet)

        connections[conn] << { :job => job, :notification => notification }
      end

      connections.each_pair do |conn, tasks|
        conn.connect! unless conn.connected?
        tasks.each do |data|
          job = data[:job]
          notif = data[:notification]

          begin
            conn.write(notif)
            @clients[project[:name]][:timestamp] = Time.now

            # TODO: Listen for error responses from Apple
            job.delete
          rescue Errno::EPIPE, OpenSSL::SSL::SSLError, Errno::ECONNRESET
            Config.logger.error "Caught error, closing connection and adding notification back to queue"

            connection.disconnect!

            job.release
          rescue RuntimeError => e
            Config.logger.error "Unable to handle: #{e}"

            job.delete
          end
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

    # Returns a hash containing a timestamp referring to when the connection was opened.
    # This timestamp will be updated to reflect when there was last activity over the socket.
    def get_client(project_name, certificate, sandbox = false)
      uri = "gateway.#{sandbox ? 'sandbox.' : ''}push.apple.com"
      unless @clients[project_name]
        @clients[project_name] = { :timestamp => Time.now, :connection => Racoon::Client.new(certificate, uri) }
      end
      @clients[project_name] ||= { :timestamp => Time.now, :connection => Racoon::Client.new(certificate, uri) }
      client = @clients[project_name]
      connection = client[:connection]

      # If the certificate has changed, but we still are connected using the old certificate,
      # disconnect and reconnect.
      unless connection.pem.eql?(certificate)
        connection.disconnect! if connection.connected?
        @clients[project_name] = { :timestamp => Time.now, :connection => Racoon::Client.new(certificate, uri) }
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

    def create_notification_from_packet(packet)
      aps = packet[:notification][:aps]

      notification = Notification.new
      notification.identifier = packet[:identifier]
      notification.expiry = packet[:expiry]
      notification.device_token = packet[:device_token]
      notification.badge = aps[:badge] if aps.has_key? :badge
      notification.alert = aps[:alert] if aps.has_key? :alert
      notification.sound = aps[:sound] if aps.has_key? :sound
      notification.custom = aps[:custom] if aps.has_key? :custom

      notification
    end
  end
end
