Gem::Specification.new do |spec| 
  spec.name = "munkey"
  spec.version = "0.0.1"
  spec.summary = "Tool for using git to push and pull from ftp servers"
  spec.description = "Tool for using git to push and pull from ftp servers"
  
  spec.files = [ 'lib/ftp_sync.rb', 'lib/munkey.rb', 'bin/munkey' ]
  spec.bindir = "bin"
  spec.executables = ["munkey"]
  spec.default_executable = "munkey"

  spec.author = "jebw"
  spec.email = "jeb@jdwilkins.co.uk"
  spec.homepage = "http://github.com/jebw/munkey"
  
  spec.test_files = []
  spec.has_rdoc = false
end