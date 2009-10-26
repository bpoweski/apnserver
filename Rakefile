require 'rubygems'
require 'rake/testtask'
require 'rake/rdoctask'

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
    gemspec.add_dependency 'daemons'
    gemspec.add_dependency 'json'
    gemspec.rubyforge_project = 'apnserver'
    gemspec.files = FileList['lib/**/*.rb', 'bin/*', '[A-Z]*', 'test/**/*'].to_a
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

Rake::TestTask.new(:test) do |test|
  test.test_files = FileList.new('test/**/test_*.rb') do |list|
    list.exclude 'test/test_helper.rb'
  end
  test.libs << 'test'
  test.verbose = true
end

Jeweler::RubyforgeTasks.new do |rubyforge|
end

Rake::RDocTask.new do |rd|
  rd.main = "README.textile"
  rd.rdoc_dir = 'rdoc'
  rd.rdoc_files.include("README.textile", "lib/**/*.rb")
end

task :default => [:test]
