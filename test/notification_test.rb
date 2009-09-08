require 'test_helper'
require 'apnserver/notification'

class NotificationTest < Test::Unit::TestCase
  include ApnServer
  
  def setup
    @notification = Notification.new
  end
  
  def test_should_generate_byte_array
    payload = '{"aps":{"alert":"You have not mail!"}}'
    device_token = "12345678123456781234567812345678"
    @notification.device_token = device_token
    @notification.alert = "You have not mail!"
    expected = [0, 0, device_token.size, device_token, 0, payload.size, payload]
    assert_equal expected.pack("ccca*cca*"), @notification.to_bytes
  end
  
  def test_should_create_payload_with_badge_attribute
    expected = { :aps => { :badge => 1 }}
    @notification.badge = 1
    assert_equal expected, @notification.payload
  end
  
  def test_should_create_payload_with_alert_attribute
    expected = { :aps => { :alert => 'Hi' }}
    @notification.alert = 'Hi'
    assert_equal expected, @notification.payload  
  end
  
  def test_should_create_json_payload
    expected = '{"aps":{"alert":"Hi"}}'
    @notification.alert = 'Hi'
    assert_equal expected, @notification.json_payload
  end
  
  def test_should_not_allow_for_payloads_larger_than_256_chars
    assert_raise Payload::PayloadInvalid do 
      alert = []
      256.times { alert << 'Hi' }
      @notification.alert = alert.join
      @notification.json_payload
    end
  end
  
  
  
end

