Gem::Specification.new do |s|
  s.name = %q{apnserver}
  s.version = "0.2.0"
  s.platform    = Gem::Platform::RUBY

  s.authors = ["Ben Poweski"]
  s.date = %q{2011-01-01}
  s.description = %q{A toolkit for proxying and sending Apple Push Notifications}
  s.email = %q{bpoweski@3factors.com}
  s.executables = ["apnsend", "apnserverd"]
  s.extra_rdoc_files = ["README.textile"]
  s.files = Dir.glob("{bin,lib}/**/*") + %w(README.textile)
  s.homepage = %q{http://github.com/bpoweski/apnserver}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{apnserver}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Apple Push Notification Toolkit}
  s.test_files = Dir.glob("spec/**/*")

  s.required_rubygems_version = ">= 1.3.6"
  s.add_dependency 'activesupport',       '~> 3.0.0'
  s.add_development_dependency 'bundler', '~> 1.0.0'
end
