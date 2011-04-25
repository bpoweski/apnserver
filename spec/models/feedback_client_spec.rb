require 'spec_helper'

module ApnServer
  describe FeedbackClient do
    describe "#new" do
      let(:feedback_client) { ApnServer::FeedbackClient.new('cert.pem', 'feedback.sandbox.push.apple.com', 2196) }

      it "sets the pem path" do
        feedback_client.pem.should == 'cert.pem'
      end

      it "sets the host" do
        feedback_client.host.should == 'feedback.sandbox.push.apple.com'
      end

      it "sets the port" do
        feedback_client.port.should == 2196
      end
    end
  end
end
