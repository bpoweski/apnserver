Gem::Specification.new do |s|
  s.name = %q{racoon}
  s.version = "0.5.0pre1"
  s.platform    = Gem::Platform::RUBY

  s.authors = ["Jeremy Tregunna"]
  s.date = %q{2011-04-24}
  s.description = %q{A toolkit for proxying and sending Apple Push Notifications prepared for a hosted environment}
  s.email = %q{jeremy.tregunna@me.com}
  s.executables = ["racoon-send", "racoon-worker", "racoon-firehose"]
  s.extra_rdoc_files = ["README.mdown"]
  s.files = Dir.glob("{bin,lib}/**/*") + %w(README.mdown)
  s.homepage = %q{https://github.com/jeremytregunna/racoon}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{racoon}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Apple Push Notification Toolkit for hosted environments}
  s.test_files = Dir.glob("spec/**/*")

  s.required_rubygems_version = ">= 1.3.6"
  s.add_dependency 'yajl-ruby', '>= 0.7.0'
  s.add_dependency 'beanstalk-client', '>= 1.0.0'
  s.add_dependency 'ffi-rzmq', '~> 0.8.0'
  s.add_development_dependency 'bundler', '~> 1.0.0'
  s.add_development_dependency 'eventmachine', '>= 0.12.8'
end
