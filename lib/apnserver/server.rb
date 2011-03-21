module ApnServer
  class Server
    attr_accessor :client, :bind_address, :port

    ONCE_A_DAY = 60 * 60 * 24

    def initialize(pem, bind_address = '0.0.0.0', port = 22195)
      @queue = EM::Queue.new
      @client = ApnServer::Client.new(pem)
      @feedback_client = ApnServer::FeedbackClient.new(pem)
      @bind_address, @port = bind_address, port
      Config.logger = Logger.new("/dev/stdout")
    end

    def start!
      EventMachine::run do
        Config.logger.info "#{Time.now} Starting APN Server on #{bind_address}:#{port}"

        EM.start_server(bind_address, port, ApnServer::ServerConnection) do |s|
          s.queue = @queue
        end

        EventMachine::PeriodicTimer.new(ONCE_A_DAY) do
          begin
            @feedback_client.connect! unless @feedback_client.connected?
            @feedback_client.read.each do |record|
              # In here, we need to inspect the record, make sure that we yank it
              # out from the database. record is a hash with keys:
              #   feedback_at, length, token
              # For debugging purposes, just print it out
              p record
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
          unless @queue.empty?
            size = @queue.size
            size.times do
              @queue.pop do |notification|
                begin
                  @client.connect! unless @client.connected?
                  @client.write(notification)
                rescue Errno::EPIPE, OpenSSL::SSL::SSLError, Errno::ECONNRESET
                  Config.logger.error "Caught Error, closing connecting and adding notification back to queue"
                  @client.disconnect!
                  @queue.push(notification)
                rescue RuntimeError => e
                  Config.logger.error "Unable to handle: #{e}"
                end
              end
            end
          end
        end
      end
    end
  end
end
