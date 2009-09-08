require 'apnserver/payload'
require 'test_helper'

class NotificationTest < Test::Unit::TestCase
  include ApnServer::Payload
  
  def test_should_create_payload_with_simple_string
    expected = { :aps => { :alert => 'Hi' }}
    assert_equal expected, create_payload('Hi')
  end
  
  def test_should_create_payload_with_alert_key
    expected = { :aps => { :alert => 'Hi' }}
    assert_equal expected, create_payload(:alert => 'Hi')    
  end
  
  def test_should_create_payload_with_badge_and_alert
    expected = { :aps => { :alert => 'Hi', :badge => 1 }}
    assert_equal expected, create_payload(:alert => 'Hi', :badge => 1)
  end
  
  # example 1
  def test_should_create_payload_with_custom_payload
    alert = 'Message received from Bob'
    expected = {
      :aps => { :alert => alert },
      :acme2 => [ "bang",  "whiz" ]
    }
    assert_equal expected, create_payload(:alert => alert, :custom => { :acme2 => ['bang', 'whiz']})
  end
  
  # example 3
  def test_should_create_payload_with_sound_and_multiple_custom
    expected = {
      :aps => {
        :alert => "You got your emails.",
        :badge => 9,
        :sound => "bingbong.aiff"
      },
      :acme1 => "bar",
      :acme2 => 42     
    }
    assert_equal expected, create_payload({
      :alert => "You got your emails.",
      :badge => 9,
      :sound => "bingbong.aiff", 
      :custom => { :acme1 => "bar", :acme2 => 42}
    })
  end
  
  # example 5
  def test_should_create_payload_with_empty_aps
    expected = {
      :aps => {},
      :acme2 => [ 5,  8 ]
    }
    assert_equal expected, create_payload(:custom => { :acme2 => [ 5,  8 ] })
  end
  
end