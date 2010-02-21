require 'net/ftp'
require 'net/ftp/list'

class FtpSync
  attr_accessor :verbose
  
  def initialize(server, user, password, ignore = nil)
    @server = server
    @user = user
    @password = password
    @connection = nil
    @ignore = ".git/\n"
    @ignore << ignore if ignore
    @recursion_level = 0
    @verbose = false
  end
  
  def pull_dir(localpath, remotepath, options = {})
    connect! unless @connection
    @recursion_level += 1
    
    todelete = Dir.glob(File.join(localpath, '*'))
    
    tocopy = []
    recurse = []
    @connection.list(remotepath) do |e|
      entry = Net::FTP::List.parse(e)
      
      paths = [ File.join(localpath, entry.basename), "#{remotepath}/#{entry.basename}" ]
      if entry.dir?
        recurse << paths
      elsif entry.file?
        tocopy << paths
      end
      todelete.delete paths[0]
    end
    
    tocopy.each do |paths|
      localfile, remotefile = paths
      @connection.get(remotefile, localfile)
      log "Pulled file #{remotefile}"
    end
    
    recurse.each do |paths|
      localdir, remotedir = paths
      Dir.mkdir(localdir) unless File.exist?(localdir)
      pull_dir(localdir, remotedir, options)
    end
    
    if options[:delete]
      todelete.each do |p|
        block_given? ? yield(p) : FileUtils.rm_rf(p)
        log "Removed path #{p}"
      end
    end
    
    @recursion_level -= 1
    close! if @recursion_level == 0
  end
  
  def push_dir(localpath, remotepath)
    connect!
    
    Dir.glob(File.join(localpath, '**', '*')) do |f|
      f.gsub!("#{localpath}/", '')
      local = File.join localpath, f
      remote = "#{remotepath}/#{f}"
      
      if File.directory?(local)
        @connection.mkdir remote rescue Net::FTPPermError
        log "Created Remote Directory #{local}"
      elsif File.file?(local)
        @connection.put local, remote
        log "Pushed file #{remote}"
      end
    end
    
    close!
  end
  
  def pull_files(localpath, remotepath, filelist)
    connect!
    filelist.each do |f|
      localdir = File.join(localpath, File.dirname(f))
      FileUtils.mkdir_p localdir unless File.exist?(localdir)
      @connection.get "#{remotepath}/#{f}", File.join(localpath, f)
      log "Pulled file #{remotepath}/#{f}"
    end
    close!
  end
  
  def push_files(localpath, remotepath, filelist)
    connect!
    
    remote_paths = filelist.map {|f| File.dirname(f) }.uniq
    create_remote_paths(remotepath, remote_paths)
    
    filelist.each do |f|
      @connection.put File.join(localpath, f), "#{remotepath}/#{f}"
      log "Pushed file #{remotepath}/#{f}"
    end
    close!
  end
  
  private
    def connect!
      @connection = Net::FTP.new(@server)
      @connection.login(@user, @password)
      log "Opened connection to #{@server}"
    end
  
    def close!
      @connection.close
      log "Closed Connection to #{@server}"
    end
    
    def create_remote_paths(base, pathlist)
      pathlist.each do |remotepath|
        parent = base
        remotepath.split('/').each do |p|
          parent = "#{parent}/#{p}"
          @connection.mkdir(parent) rescue Net::FTPPermError
          log "Creating Remote Directory #{parent}"
        end
      end
    end
    
    def log(msg)
      puts msg if @verbose
    end
end