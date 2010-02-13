require 'net/ftp'
require 'net/ftp/list'

class FtpSync
  attr_reader :connection
  
  def initialize(server, user, password, ignore = nil)
    @server = server
    @user = user
    @password = password
    @connection = nil
    @ignore = ignore
  end
  
  def pull_all(localpath, remotepath)
    tocopy = []
    recurse = []
    @connection.list(remotepath) do |entry|
      paths = [ File.join(localpath, entry.basename), "#{remotepath}/#{entry.basename}" ]
      if entry.dir?
        recurse << paths
      elsif entry.file?
        tocopy << paths
      end
    end
    
    tocopy.each do |paths|
      localfile, remotefile = paths
      @connection.get(remotefile, localfile)
    end
    
    recurse.each do |paths|
      localdir, remotedir = paths
      Dir.mkdir(localdir) if not File.exist?(localdir)
      pull_all(localdir, remotedir)
    end
  end
  
  def push(localpath, remotepath)
    #should recursively push all files up
  end
  
  def pull_files(localpath, remotepath, filelist)
    #should pull a list of files down
  end
  
  def push_files(localpath, remotepath, filelist)
    #should push a list of files up
  end
  
#  private
    def connect!
      @connection = Net::FTP.new(@server)
      @connection.login(@user, @password)
    end
  
    def close!
      @connection.close
    end
end