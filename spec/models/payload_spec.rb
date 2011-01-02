require 'spec_helper'

module ApnServer
  describe Payload do
    describe "#payload.create_payload" do
      let(:payload) { Class.new.send(:include, Payload).new }

      it "creates a payload_with_simple_string" do
        payload.create_payload('Hi').should == { :aps => { :alert => 'Hi' }}
      end

      it "creates a payload_with_alert_key" do
        payload.create_payload(:alert => 'Hi').should == { :aps => { :alert => 'Hi' }}
      end

      it "creates payload with badge_and_alert" do
        payload.create_payload(:alert => 'Hi', :badge => 1).should == { :aps => { :alert => 'Hi', :badge => 1 }}
      end

      # example 1
      it "test_should_payload.create_payload_with_custom_payload" do
        alert = 'Message received from Bob'
        payload.create_payload(:alert => alert, :custom => { :acme2 => ['bang', 'whiz']}).should == {
          :aps => { :alert => alert },
          :acme2 => [ "bang",  "whiz" ]
        }
      end

      # example 3
      it "test_should_payload.create_payload_with_sound_and_multiple_custom" do
        expected = {
          :aps => {
            :alert => "You got your emails.",
            :badge => 9,
            :sound => "bingbong.aiff"
          },
          :acme1 => "bar",
          :acme2 => 42
        }
        payload.create_payload({
          :alert => "You got your emails.",
          :badge => 9,
          :sound => "bingbong.aiff",
          :custom => { :acme1 => "bar", :acme2 => 42}
        }).should == expected
      end

      # example 5
      it "test_should_payload.create_payload_with_empty_aps" do
        payload.create_payload(:custom => { :acme2 => [ 5,  8 ] }).should == {
          :aps => {},
          :acme2 => [ 5,  8 ]
        }
      end
    end
  end
end