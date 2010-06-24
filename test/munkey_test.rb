require 'test/unit'
require 'tmpdir'
require 'munkey'

class MunkeyTest < Test::Unit::TestCase
  
  def setup
    Net::FTP.create_ftp_src
    @gitdir = File.join Dir.tmpdir, create_tmpname
  end
  
  def teardown
    FileUtils.rm_rf @gitdir
    FileUtils.rm_rf Net::FTP.ftp_src
    FileUtils.rm_rf Net::FTP.ftp_dst if File.exist?(Net::FTP.ftp_dst)
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
    Munkey.clone('ftp://user:pass@test.server/', @gitdir, :ignores => '*.txt')
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
    FileUtils.touch File.join(Net::FTP.ftp_src, 'missing')
    assert !File.exist?(File.join(@gitdir, 'missing'))
    munkey.pull
    assert File.exist?(File.join(@gitdir, 'missing'))
  end
  
  def test_pull_removes_missing_files
    munkey = Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    File.unlink File.join(Net::FTP.ftp_src, 'README')
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
  
  def test_pull_adds_a_commit
    munkey = Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    FileUtils.touch File.join(Net::FTP.ftp_src, 'missing')
    munkey.pull
    Dir.chdir(@gitdir) do
      commits = `git log --format=oneline`.strip.split("\n")
      assert_equal 2, commits.size
    end
  end
  
  def test_pull_with_no_merge_commits_to_munkey_branch_but_not_master
    munkey = Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    Dir.chdir(@gitdir) do
      munkey_commits = `git log --format=oneline munkey`.strip.split("\n").size
      master_commits = `git log --format=oneline master`.strip.split("\n").size
      FileUtils.touch File.join(Net::FTP.ftp_src, 'missing')
      munkey.pull(false)
      assert_equal munkey_commits + 1, `git log --format=oneline munkey`.strip.split("\n").size
      assert_equal master_commits, `git log --format=oneline master`.strip.split("\n").size
    end    
  end
  
  def test_push_includes_newly_added_files
    Net::FTP.create_ftp_dst
    munkey = Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    add_file_to_git 'newfile'
    munkey.push
    assert File.exist?(File.join(Net::FTP.ftp_dst, 'newfile'))
  end
  
  def test_push_includes_files_from_multiple_commits
    Net::FTP.create_ftp_dst
    munkey = Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    add_file_to_git('newfile')
    add_file_to_git('secondfile')
    munkey.push
    assert File.exist?(File.join(Net::FTP.ftp_dst, 'newfile'))
    assert File.exist?(File.join(Net::FTP.ftp_dst, 'secondfile'))
  end
  
  def test_push_excludes_remote_added_files
    Net::FTP.create_ftp_dst
    munkey = Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    FileUtils.touch File.join(Net::FTP.ftp_src, 'another')
    munkey.pull
    munkey.push
    assert !File.exist?(File.join(Net::FTP.ftp_dst, 'another'))
  end
  
  def test_push_excludes_existing_files
    Net::FTP.create_ftp_dst
    munkey = Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    add_file_to_git 'newfile'
    munkey.push
    assert File.exist?(File.join(Net::FTP.ftp_dst, 'newfile'))
    assert !File.exist?(File.join(Net::FTP.ftp_dst, 'README'))
  end
  
  def test_push_excludes_gitignore
    Net::FTP.create_ftp_dst
    munkey = Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    add_file_to_git '.gitignore'
    munkey.push
    assert !File.exist?(File.join(Net::FTP.ftp_dst, '.gitignore'))
  end
  
  def test_push_includes_files_changed_on_both_local_and_remote
    Net::FTP.create_ftp_dst
    File.open(File.join(Net::FTP.ftp_src, 'README'), 'w') do |f| 
      f.write "line 1\nline 2\nline 3\nline 4\n"
    end
    munkey = Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    File.open(File.join(Net::FTP.ftp_src, 'README'), 'w') do |f| 
      f.write "line 1\nline 2\nline 3\nline 4\nline 5\n"
    end
    File.open(File.join(@gitdir, 'README'), 'w') do |f|
      f.write "line 1\nline two\nline 3\nline 4\n"
    end
    munkey.pull
    munkey.push
    assert File.exist?(File.join(Net::FTP.ftp_dst, 'README'))
  end
  
  def test_push_removes_locally_removed_files
    FileUtils.cp_r Net::FTP.ftp_src, Net::FTP.ftp_dst
    munkey = Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    Dir.chdir(@gitdir) do
      system("git rm README && git commit -m 'removed README'")
    end
    assert File.exist?(File.join(Net::FTP.ftp_dst, 'README'))
    munkey.push
    assert !File.exist?(File.join(Net::FTP.ftp_dst, 'README'))
  end
  
  def test_push_excludes_remotely_removed_files
    FileUtils.cp_r Net::FTP.ftp_src, Net::FTP.ftp_dst
    munkey = Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    File.unlink File.join(Net::FTP.ftp_src, 'README')
    munkey.pull
    munkey.push
    assert File.exist?(File.join(Net::FTP.ftp_dst, 'README'))
  end
  
  def test_push_excludes_files_with_same_change_local_and_remote
    Net::FTP.create_ftp_dst
    munkey = Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    File.open(File.join(Net::FTP.ftp_src, 'README'), 'w') {|f| f.write 'munkey' }
    Dir.chdir(@gitdir) do
      File.open('README', 'w') {|f| f.write 'munkey' }
      system("git add . && git commit -m 'add README CHANGES'")
    end
    munkey.pull
    munkey.push
    assert !File.exist?(File.join(Net::FTP.ftp_dst, 'README'))
  end
  
  def test_push_adds_a_commit_to_the_munkey_branch
    Net::FTP.create_ftp_dst
    munkey = Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    add_file_to_git('newfile')
    add_file_to_git('secondfile')
    munkey.push
    Dir.chdir(@gitdir) do
      commits = `git log --format=oneline munkey`.strip.split("\n")
      assert_equal 3, commits.size
    end
  end
  
  def test_dryrun_push_doesnt_create_commit_in_munkey_branch
    Net::FTP.create_ftp_dst
    munkey = Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    last_commit = File.read File.join(@gitdir, '.git', 'refs', 'heads', 'munkey')
    add_file_to_git 'newfile'
    munkey.push(true)
    assert_equal last_commit, File.read(File.join(@gitdir, '.git', 'refs', 'heads', 'munkey'))
  end
  
  def test_dryrun_push_doesnt_upload_files
    Net::FTP.create_ftp_dst
    munkey = Munkey.clone('ftp://user:pass@test.server/', @gitdir)
    add_file_to_git 'newfile'
    munkey.push(true)
    assert !File.exist?(File.join(Net::FTP.ftp_dst, 'newfile'))
  end
  
  protected
   def create_tmpname
    tmpname = ''
    char_list = ("a".."z").to_a + ("0".."9").to_a
		1.upto(20) { |i| tmpname << char_list[rand(char_list.size)] }
		return tmpname
  end
  
  def add_file_to_git(filename, content = nil)
    Dir.chdir(@gitdir) do
      File.open(filename, 'a') {|f| f.write content }      
      system("git add . && git commit -m 'Added file #{filename}'")
    end
  end
end