require 'tmpdir'

module Net
  class FTP
    @@listing_overrides = {}
    
    class << self
      
      def ftp_src
        @ftp_src ||= File.join(Dir.tmpdir, 'munkey_ftp_src')
      end
      
      def ftp_src=(src)
        @ftp_src = src
      end
      
      def create_ftp_src
        FileUtils.mkdir_p File.join(ftp_src, 'dirA', 'dirAA')
        FileUtils.mkdir_p File.join(ftp_src, 'dirB')
        FileUtils.touch File.join(ftp_src, 'README')
        FileUtils.touch File.join(ftp_src, 'fileA')
        FileUtils.touch File.join(ftp_src, 'fileB')
        FileUtils.touch File.join(ftp_src, 'dirA', 'fileAA')
        FileUtils.touch File.join(ftp_src, 'dirA', 'dirAA', 'fileAAA')
        FileUtils.touch File.join(ftp_src, 'dirB', 'fileBA')
        FileUtils.touch File.join(ftp_src, 'dirB', 'fileBB')
      end
      
      def ftp_dst
        @ftp_dst ||= File.join(Dir.tmpdir, 'munkey_ftp_dst')
      end
      
      def ftp_dst=(dst)
        @ftp_dst = dst
      end
    
      def create_ftp_dst
        FileUtils.mkdir_p ftp_dst
      end
      
      def listing_overrides
        @@listing_overrides ||= {}
      end
      
      def listing_overrides=(overrides)
        @@listing_overrides = overrides
      end
    end
    
    def initialize(server)
      raise SocketError unless server == 'test.server'
    end
    
    def inspect
      "Mocked Net::FTP server=#{@server}"
    end
    
    def login(user, pass)
      raise Net::FTPPermError unless user == 'user' && pass == 'pass'
    end
    
    def get(src, dst)
      raise Net::FTPPermError unless File.exist?(src_path(src))
      FileUtils.cp src_path(src), dst
    end
    
    def put(src, dst)
      d,f = File.split(dst)
      raise Net::FTPPermError unless File.exist?(dst_path(d))
      FileUtils.cp src, dst_path(dst)
    end
    
    def mkdir(dir)
      d,sd = File.split(dir)
      raise Net::FTPPermError if File.exist?(dst_path(dir))
      raise Net::FTPPermError unless File.exist?(dst_path(d))
      FileUtils.mkdir dst_path(dir)
    end
    
    def chdir(dir)
      raise Net::FTPPermError unless File.exist?(src_path(dir))
    end
    
    def list(dir)
      paths = if @@listing_overrides[dir]
        @@listing_overrides[dir]
      elsif File.exist?(src_path(dir))
        `ls -l #{src_path(dir)}`.strip.split("\n")
      else
        []
      end

      paths.each {|e| yield(e) } if block_given?
      paths
    end
    
    def delete(file)
      raise Net::FTPPermError unless File.exist?(dst_path(file))
      File.unlink(dst_path(file))
    end
    
    def close; end
    
    private
      def src_path(p)
        File.join(self.class.ftp_src, p)
      end
      
      def dst_path(p)
        File.join(self.class.ftp_dst, p)
      end
  end
  
  class FTPPermError < RuntimeError; end  
end

class SocketError < RuntimeError; end
