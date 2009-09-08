require 'rubygems'
require 'test/unit'

def symbolize_keys(hash)  
  hash.inject({}) do |result, (key, value)|  
    new_key = case key  
      when String then key.to_sym  
    else key  
    end  
    new_value = case value  
      when Hash then symbolize_keys(value)  
    else value  
    end  
    result[new_key] = new_value  
    result  
  end
end  