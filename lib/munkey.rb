require 'uri'
require 'ftp_sync'
require 'YAML'

class Munkey
  
  class << self
    def clone(ftpsrc, repo_path, ignores = nil)
      src = URI::parse(ftpsrc)
      raise InvalidSource unless src.is_a?(URI::FTP)
      
      repo = create_repo(repo_path, ignores)
      repo.save_ftp_details(src)
      repo.pull_ftp_files
      repo.commit_changes
      repo.create_branch
      repo
    end
    
    private
      def create_repo(repo_path, ignores = nil)
        return false unless system("git init #{repo_path}")
        if ignores
          File.open(File.join(repo_path, '.gitignore'), 'w') do |f|
            f.write ignores
          end
          system("cd #{repo_path} && git add .gitignore")
        end
        new(repo_path)
      end
  end
  
  def initialize(gitpath)
    @gitpath = gitpath
    munkey_file = File.join(gitpath, '.git', 'munkey.yml')
    @ftpdetails = YAML.load_file(munkey_file) if File.exist?(munkey_file)
  end
  
  def save_ftp_details(ftp_uri)
    @ftpdetails = { :host => ftp_uri.host, :path => "/#{ftp_uri.path}", :user => ftp_uri.user, :password => ftp_uri.password }
    File.open File.join(@gitpath, '.git', 'munkey.yml'), 'w' do |f|
      f.write @ftpdetails.to_yaml
    end
  end
  
  def pull_ftp_files()
    ftp = FtpSync.new(@ftpdetails[:host], @ftpdetails[:user], @ftpdetails[:password])
    ftp.pull_dir(@gitpath, @ftpdetails[:path])
  end
  
  def commit_changes()
    Dir.chdir(@gitpath) do
      system("git add .") && system("git commit -m 'Pull from ftp://#{@ftpdetails[:host]}#{@ftpdetails[:path]} at #{Time.now.to_s}'")
    end
  end
  
  def create_branch(branch_name = 'munkey')
    Dir.chdir(@gitpath) do
      system("git branch #{branch_name}")
    end
  end
end