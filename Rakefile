require 'rubygems'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "apnserver"
    gemspec.summary = "Apple Push Notification Server"
    gemspec.description = "A toolkit for proxying and sending Apple Push Notifications"
    gemspec.email = "bpoweski@3factors.com"
    gemspec.homepage = "http://github.com/bpoweski/apnserver"
    gemspec.authors = ["Ben Poweski"]
    gemspec.add_dependency 'eventmachine'
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.test_files = FileList.new('test/**/test_*.rb') do |list|
    list.exclude 'test/test_helper.rb'
  end
  test.libs << 'test'
  test.verbose = true
end

task :default => [:test]