Dir['tasks/**/*.rake'].each { |t| load t }

require 'rake/rdoctask'
Rake::RDocTask.new do |rd|
  rd.main = "README.mdown"
  rd.rdoc_dir = 'rdoc'
  rd.rdoc_files.include("README.mdown", "lib/**/*.rb")
end

task :default => [:spec]
