require 'spec_helper'

module ApnServer
  describe Notification do
    let(:notification) { Notification.new }

    describe "#to_bytes" do
      it "generates a byte array" do
        payload = '{"aps":{"alert":"You have not mail!"}}'
        device_token = "12345678123456781234567812345678"
        notification.device_token = device_token
        notification.alert = "You have not mail!"
        expected = [0, 0, device_token.size, device_token, 0, payload.size, payload]
        notification.to_bytes.should == expected.pack("ccca*CCa*")
      end
    end

    describe "#payload" do
      it "generates the badge element" do
        expected = { :aps => { :badge => 1 }}
        notification.badge = 1
        notification.payload.should == expected
      end

      it "generates the alert alement" do
        expected = { :aps => { :alert => 'Hi' }}
        notification.alert = 'Hi'
        notification.payload.should == expected
      end
    end

    describe "#json_payload" do
      it "converts payload to json" do
        expected = '{"aps":{"alert":"Hi"}}'
        notification.alert = 'Hi'
        notification.json_payload.should == expected
      end

      it "does not allow payloads larger than 256 chars" do
        lambda {
          alert = []
          256.times { alert << 'Hi' }
          notification.alert = alert.join
          notification.json_payload
        }.should raise_error(Payload::PayloadInvalid)
      end
    end

    describe "#valid?" do
      it "recognizes a valid request" do
        device_token = '12345678123456781234567812345678'
        payload = '{"aps":{"alert":"You have not mail!"}}'
        request = [0, 0, device_token.size, device_token, 0, payload.size, payload].pack("CCCa*CCa*")
        Notification.valid?(request).should be_true
        notification = Notification.parse(request)
        notification.device_token.should == device_token
        notification.alert.should == "You have not mail!"
      end

      it "recognizes an invalid request" do
        device_token = '123456781234567812345678'
        payload = '{"aps":{"alert":"You have not mail!"}}'
        request = [0, 0, 32, device_token, 0, payload.size, payload].pack("CCCa*CCa*")
        Notification.valid?(request).should be_false
      end
    end

    describe "#parse" do
      it "reads a byte array and constructs a notification" do
        device_token = '12345678123456781234567812345678'
        notification.device_token = device_token
        notification.badge = 10
        notification.alert = 'Hi'
        notification.sound = 'default'
        notification.custom = { 'acme1' => "bar", 'acme2' => 42}

        parsed = Notification.parse(notification.to_bytes)
        [:device_token, :badge, :alert, :sound, :custom].each do |k|
          expected = notification.send(k)
          parsed.send(k).should == expected
        end
      end
    end
  end
end