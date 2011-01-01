require 'spec_helper'

module ApnServer
  describe Client do
    describe "#new" do
      let(:client) { ApnServer::Client.new('cert.pem', 'gateway.sandbox.push.apple.com', 2196) }

      it "sets the pem path" do
        client.pem.should == 'cert.pem'
      end

      it "sets the host" do
        client.host.should == 'gateway.sandbox.push.apple.com'
      end

      it "sets the port" do
        client.port.should == 2196
      end
    end
  end
end
