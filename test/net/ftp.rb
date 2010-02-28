module Net
  class FTP
    class << self
      def ftp_src
        @ftp_src ||= set_ftp_src
      end
      
      def ftp_src=(src)
        @ftp_src = src
      end
      
      def set_ftp_src
        src = {}
        src['/'] = [ 
          "-rw-r--r--   1 user  users  100 Feb 20 22:57 README",
          "drwxr-xr-x   1 user  users  100 Feb 20 22:57 dirA",
          "drwxr-xr-x   1 user  users  100 Feb 20 22:57 dirB",
          "-rw-r--r--   1 user  users  100 Feb 20 22:57 fileA",
          "-rw-r--r--   1 user  users  100 Feb 20 22:57 fileB",
        ]
        src['/dirA'] = [
          "-rw-r--r--   1 user  users  100 Feb 20 22:57 fileAA",
          "drwxr-xr-x   1 user  users  100 Feb 20 22:57 dirAA"
        ]
        src['/dirAA'] = [
          "-rw-r--r--   1 user  users  100 Feb 20 22:57 fileAAA"
        ]
        src['/dirB'] = [
          "-rw-r--r--   1 user  users  100 Feb 20 22:57 fileBA",
          "-rw-r--r--   1 user  users  100 Feb 20 22:57 fileBB"
        ]
        src
      end
    end
    
    def initialize(server)
      raise SocketError unless server == 'test.server'
    end
    
    def login(user, pass)
      raise Net::FTPPermError unless user == 'user' && pass == 'pass'
    end
    
    def get(src, dst)
      d,f = File.split(src)
      raise Net::FTPPermError unless self.class.ftp_src.keys.include?(d)
      raise Net::FTPPermError unless self.class.ftp_src[d].any? {|e| Net::FTP::List.parse(e).basename == f }
      FileUtils.touch(dst)
    end
    
    def chdir(dir)
      raise Net::FTPPermError unless self.ftp_src.keys.include?(dir)
    end
    
    def close; end
  end
  
  class FTPPermError < RuntimeError; end  
end

class SocketError < RuntimeError; end
