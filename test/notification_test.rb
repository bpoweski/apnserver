require 'test_helper'
require 'apnserver/notification'

class NotificationTest < Test::Unit::TestCase
  include ApnServer
  
  def setup
    @notification = Notification.new
  end
  
  def test_notification_should_generate_byte_array
    payload = '{"aps":{"alert":"You have not mail!"}}'
    device_token = "12345678123456781234567812345678"
    @notification.device_token = device_token
    @notification.alert = "You have not mail!"
    expected = [0, 0, device_token.size, device_token, 0, payload.size, payload]
    assert_equal expected.pack("ccca*cca*"), @notification.to_bytes
  end
  
end

