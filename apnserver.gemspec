Gem::Specification.new do |s|
  s.name = %q{apnserver}
  s.version = "0.0.1"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ben Poweski"]
  s.autorequire = %q{apnserver}
  s.date = %q{2009-07-09}
  s.description = %q{A Ruby Server for Sending iPhone Notifications}
  s.email = %q{bpoweski@gmail.com}
  s.extra_rdoc_files = ["MIT-LICENSE"]
  s.files = ["MIT-LICENSE", "README.textile", "Rakefile", "lib/apns", "lib/apns/core.rb", "lib/apns/notification.rb", "lib/apns.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/bpoweski/apnserver}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A Ruby server and command line toolkit for sending Apple push notifications}
 
  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2
 
    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end