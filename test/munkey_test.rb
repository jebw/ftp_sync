require 'test/unit'
require 'tmpdir'
require 'munkey'

class MunkeyTest < Test::Unit::TestCase
  
  def setup
    Net::FTP.reset_ftp_src
    @gitdir = File.join Dir.tmpdir, create_tmpname
  end
  
  def teardown
    FileUtils.rm_rf @gitdir
  end
  
  def test_clone_creates_supplied_target_dir
    Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    assert File.exist?(@gitdir)
  end
  
  def test_clone_initialises_git_in_target_dir
    Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    assert File.exist?(File.join(@gitdir, '.git'))
  end
  
  def test_clone_creates_git_ignore_with_supplied_ignores
    Munkey.clone('ftp://user:pass@test.server/', @gitdir, '*.txt')
    assert File.exist?(File.join(@gitdir, '.gitignore'))
    assert_equal "*.txt", File.read(File.join(@gitdir, '.gitignore'))
  end
  
  def test_clone_saves_ftp_details
    Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    assert File.exist?(File.join(@gitdir, '.git', 'munkey.yml'))
    ftp_details = YAML.load(File.read(File.join(@gitdir, '.git', 'munkey.yml')))
    assert_equal 'test.server', ftp_details[:host]
    assert_equal 'user', ftp_details[:user]
    assert_equal 'pass', ftp_details[:password]
    assert_equal '/', ftp_details[:path]
  end
  
  def test_clone_pulls_in_files_from_ftp
    Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    assert File.exist?(File.join(@gitdir, 'README'))
    assert File.exist?(File.join(@gitdir, 'dirA'))
    assert File.exist?(File.join(@gitdir, 'dirA', 'fileAA'))
  end
  
  def test_clone_adds_files_to_git
    Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    Dir.chdir(@gitdir) do
      status = `git status`
      assert_no_match /untracked files present/, status
    end
  end
  
  def test_clone_creates_a_munkey_branch
    Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    Dir.chdir(@gitdir) do
      branches = `git branch`.split("\n").map {|b| b.gsub(/^\*/, '').strip }
      assert branches.include?('master')
      assert branches.include?('munkey')
    end
  end
  
  def test_pull_adds_new_files
    munkey = Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    Net::FTP.ftp_src['/'] << "-rw-r--r--   1 user  users  100 Feb 20 22:57 missing"
    assert !File.exist?(File.join(@gitdir, 'missing'))
    munkey.pull
    assert File.exist?(File.join(@gitdir, 'missing'))
  end
  
  def test_pull_removes_missing_files
    munkey = Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    Net::FTP.ftp_src['/'].shift
    assert File.exist?(File.join(@gitdir, 'README'))
    munkey.pull
    assert !File.exist?(File.join(@gitdir, 'README'))
  end
  
  def test_pull_doesnt_change_locally_removed_files
    munkey = Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    readme = File.join(@gitdir, 'README')
    File.unlink(readme)
    assert !File.exist?(readme)
    munkey.pull
    assert !File.exist?(readme)
  end
  
  protected
   def create_tmpname
      tmpname = ''
      char_list = ("a".."z").to_a + ("0".."9").to_a
			1.upto(20) { |i| tmpname << char_list[rand(char_list.size)] }
			return tmpname
    end
end