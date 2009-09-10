require File.dirname(__FILE__) + '/test_helper.rb'

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
  
  def test_should_recognize_valid_request
    device_token = '12345678123456781234567812345678'
    payload = '{"aps":{"alert":"You have not mail!"}}'
    request = [0, 0, device_token.size, device_token, 0, payload.size, payload].pack("ccca*cca*")
    assert Notification.valid?(request)
    notification = Notification.parse(request)
    assert_equal device_token, notification.device_token
    assert_equal "You have not mail!", notification.alert
  end
  
  def test_should_not_recognize_invalid_request
    device_token = '12345678123456781234567812345678'
    payload = '{"aps":{"alert":"You have not mail!"}}'
    request = [0, 0, 20, device_token, 0, payload.size, payload].pack("ccca*cca*")
    assert !Notification.valid?(request)
  end
  
  def test_should_pack_and_unpack_json
    device_token = '12345678123456781234567812345678'
    notification = Notification.new
    notification.device_token = device_token
    notification.badge = 10
    notification.alert = 'Hi'
    notification.sound = 'default'
    notification.custom = { 'acme1' => "bar", 'acme2' => 42}
    
    parsed = Notification.parse(notification.to_bytes)
    [:device_token, :badge, :alert, :sound, :custom].each do |k|
      expected = notification.send(k)
      assert_equal expected, parsed.send(k), "Expected #{k} to be #{expected}"
    end
  end
end
