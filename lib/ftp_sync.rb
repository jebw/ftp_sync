require 'net/ftp'
require 'rubygems'
require 'net/ftp/list'
require 'fileutils'

# A Ruby library for recursively downloading and uploading directories to/from ftp
# servers. Also supports uploading and downloading a list of files relative to 
# the local/remote roots. You can specify a timestamp to only download files 
# newer than that timestamp, or only download files newer than their local copy.
class FtpSync
  
  attr_accessor :verbose, :server, :user, :password, :passive
  
  # Creates a new instance for accessing a ftp server 
  # requires +server+, +user+, and +password+ options
  # * :ignore - Accepts an instance of class which has an ignore? method, taking a path and returns true or false, for whether to ignore the file or not.
  # * :verbose - Whether should be verbose
  def initialize(server, user, password, options = {})
    @server = server
    @user = user
    @password = password
    @connection = nil
    @ignore = options[:ignore]
    @recursion_level = 0
    @verbose = options[:verbose] || false
    @passive = options[:passive] || false
  end
  
  # Recursively pull down files
  # :since => true - only pull down files newer than their local counterpart, or with a different filesize
  # :since => Time.now - only pull down files newer than the supplied timestamp, or with a different filesize
  # :delete => Remove local files which don't exist on the FTP server
  # If a block is supplied then it will be called to remove a local file
  
  def pull_dir(localpath, remotepath, options = {}, &block)
    connect! unless @connection
    @recursion_level += 1

    todelete = Dir.glob(File.join(localpath, '*'))
    
    tocopy = []
    recurse = []

    # To trigger error if path doesnt exist since list will
    # just return and empty array
    @connection.chdir(remotepath) 

    @connection.list(remotepath) do |e|
      entry = Net::FTP::List.parse(e)
      
      paths = [ File.join(localpath, entry.basename), "#{remotepath}/#{entry.basename}".gsub(/\/+/, '/') ]

      if entry.dir?
        recurse << paths
      elsif entry.file?
        if options[:since] == :src
          tocopy << paths unless File.exist?(paths[0]) and entry.mtime < File.mtime(paths[0]) and entry.filesize == File.size(paths[0])
        elsif options[:since].is_a?(Time)
          tocopy << paths unless entry.mtime < options[:since] and File.exist?(paths[0]) and entry.filesize == File.size(paths[0])
        else
          tocopy << paths
        end
      end
      todelete.delete paths[0]
    end
    
    tocopy.each do |paths|
      localfile, remotefile = paths
      unless should_ignore?(localfile)
        begin
          @connection.get(remotefile, localfile)
          log "Pulled file #{remotefile}"
        rescue Net::FTPPermError
          log "ERROR READING #{remotefile}"
          raise Net::FTPPermError unless options[:skip_errors]
        end        
      end
    end
    
    recurse.each do |paths|
      localdir, remotedir = paths
      Dir.mkdir(localdir) unless File.exist?(localdir)
      pull_dir(localdir, remotedir, options, &block)
    end
    
    if options[:delete]
      todelete.each do |p|
        block_given? ? yield(p) : FileUtils.rm_rf(p)
        log "Removed path #{p}"
      end
    end
    
    @recursion_level -= 1
    close! if @recursion_level == 0
  rescue Net::FTPPermError
    close!
    raise Net::FTPPermError
  end
  
  # Recursively push a local directory of files onto an FTP server
  def push_dir(localpath, remotepath)
    connect!
    
    Dir.glob(File.join(localpath, '**', '*')) do |f|
      f.gsub!("#{localpath}/", '')
      local = File.join localpath, f
      remote = "#{remotepath}/#{f}".gsub(/\/+/, '/')
            
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
  
  # Pull a supplied list of files from the remote ftp path into the local path
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
  
  # Push a supplied list of files from the local path into the remote ftp path
  def push_files(localpath, remotepath, filelist)
    connect!
    
    remote_paths = filelist.map {|f| File.dirname(f) }.uniq.reject{|p| p == '.' }
    create_remote_paths(remotepath, remote_paths)
    
    filelist.each do |f|
      @connection.put File.join(localpath, f), "#{remotepath}/#{f}"
      log "Pushed file #{remotepath}/#{f}"
    end
    close!
  end
  
  # Remove listed files from the FTP server
  def remove_files(basepath, filelist)
    connect!
    
    filelist.each do |f| 
      begin
        @connection.delete "#{basepath}/#{f}".gsub(/\/+/, '/') 
        log "Removed file #{basepath}/#{f}"
      rescue Net::FTPPermError => e
        raise e unless /^550/ =~ e.message
      end
    end
    
    close!
  end
  
  # Chains off to the (if supplied) Ignore class, ie GitIgnores.new.ignore?('path/to/my/file')
  def should_ignore?(path)
    @ignore && @ignore.ignore?(path)
  end
  
  private
    def connect!
      @connection = Net::FTP.new(@server)
      @connection.passive = @passive
      @connection.login(@user, @password)
      log "Opened connection to #{@server}"
    end
  
    def close!
      @connection.close
      log "Closed Connection to #{@server}"
    end
    
    def create_remote_paths(base, pathlist)
      base = '' if base == '/'
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
