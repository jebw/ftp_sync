Gem::Specification.new do |spec| 
  spec.name = "ftp_sync"
  spec.version = "0.4.2"
  spec.summary = "Library for syncing files and dirs with ftp servers"
  spec.description = "Library for recursively downloading and uploading entire directories from FTP servers. "
  spec.description << "Supports 'quick' downloads pulling only files changed since a specified date and uploading downloading lists of files. "
  spec.description << "Split out from Munkey - a Git <-> FTP tool"
  
  spec.files = [ 'lib/ftp_sync.rb', 'README.rdoc' ]

  spec.author = "jebw"
  spec.email = "jeb@jdwilkins.co.uk"
  spec.homepage = "http://github.com/jebw/ftp_sync"
  
  spec.test_files = [ 'test/ftp_sync_test.rb', 'test/net/ftp.rb' ]
  spec.extra_rdoc_files = [ "README.rdoc" ]
  spec.has_rdoc = true
  spec.rdoc_options = ["--line-numbers", "--title", spec.summary, "--main", "README.rdoc"]
  
  spec.add_dependency 'net-ftp-list', '>= 2.1.1'
end