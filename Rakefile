Dir['tasks/**/*.rake'].each { |t| load t }

require 'rake/rdoctask'
Rake::RDocTask.new do |rd|
  rd.main = "README.mdown"
  rd.rdoc_dir = 'rdoc'
  rd.rdoc_files.include("README.mdown", "lib/**/*.rb")
end

gemspec = eval(File.read("racoon.gemspec"))
task :build => "#{gemspec.full_name}.gem"
file "#{gemspec.full_name}.gem" => gemspec.files + ["racoon.gemspec"] do
  system "gem build racoon.gemspec"
  system "gem install racoon-#{gemspec.version}.gem"
end

task :submit_gem => "racoon-#{gemspec.version}.gem" do
  system "gem push racoon-#{gemspec.version}.gem"
end

task :default => [:spec]
