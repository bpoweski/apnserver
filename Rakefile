Dir['tasks/**/*.rake'].each { |t| load t }

require 'rake/rdoctask'
Rake::RDocTask.new do |rd|
  rd.main = "README.textile"
  rd.rdoc_dir = 'rdoc'
  rd.rdoc_files.include("README.textile", "lib/**/*.rb")
end

task :default => [:spec]
