require 'rubygems'
require 'test/unit'
require 'net/ftp'
require 'ftp_sync'
require 'tmpdir'

class Ignore
  def ignore?(p); p == 'ignore' ? true : false; end
end

class FtpSyncTest < Test::Unit::TestCase
  
  def setup
    Net::FTP.reset_ftp_src
    @dst = File.join Dir.tmpdir, create_tmpname
    FileUtils.mkdir_p @dst
    @ftp = FtpSync.new('test.server', 'user', 'pass')
  end
  
  def teardown
    FileUtils.rm_rf @dst
  end
  
  def test_can_initialize_with_params
    assert_equal 'test.server', @ftp.server
    assert_equal 'user', @ftp.user
    assert_equal 'pass', @ftp.password
  end
  
  def test_can_set_verbose
    @ftp.verbose = true
    assert_equal true, @ftp.verbose
    @ftp.verbose = false
    assert_equal false, @ftp.verbose  
  end
  
  def test_setting_an_ignore_object    
    ftp = FtpSync.new('localhost', 'user', 'pass', Ignore.new)
    assert ftp.should_ignore?('ignore')
    assert !ftp.should_ignore?('something')
  end  
  
  def test_pulling_from_an_unknown_server
    assert_raise SocketError do
      ftp = FtpSync.new('unknown.server', 'user', 'pass')
      ftp.pull_files(@dst, '/', ['README'])
    end
  end
  
  def test_pulling_files_with_bad_account_details
    assert_raise Net::FTPPermError do
      ftp = FtpSync.new('test.server', 'unknown', 'unknown')
      ftp.pull_files(@dst, '/', ['README'])
    end
  end
  
  def test_pulling_files
    @ftp.pull_files(@dst, '/', ['README', 'fileA'])
    assert File.exist?(File.join(@dst, 'README'))
    assert File.exist?(File.join(@dst, 'fileA'))
  end
  
  def test_pulling_unknown_files
    assert_raise Net::FTPPermError do
      @ftp.pull_files(@dst, '/', ['unknown' ])
    end
  end
  
  def test_pulling_files_from_subdirs
    @ftp.pull_files(@dst, '/', ['dirA/fileAA'])
    assert File.exist?(File.join(@dst, 'dirA/fileAA'))
  end
  
  def test_pull_dir_from_root
    @ftp.pull_dir(@dst, '/')
    assert File.exist?(File.join(@dst, 'fileA'))
    assert File.exist?(File.join(@dst, 'fileB'))
    assert File.exist?(File.join(@dst, 'dirA/fileAA'))
    assert File.exist?(File.join(@dst, 'dirA/dirAA/fileAAA'))
    assert File.exist?(File.join(@dst, 'dirB/fileBA'))
    assert File.exist?(File.join(@dst, 'dirB/fileBB'))
  end
  
  def test_pull_dir_from_subdir
    @ftp.pull_dir(@dst, '/dirA')
    assert File.exist?(File.join(@dst, 'fileAA'))
    assert File.exist?(File.join(@dst, 'dirAA/fileAAA'))
  end
  
  def test_pull_dir_from_nonexistant_dir
    assert_raise Net::FTPPermError do
      @ftp.pull_dir(@dst, 'something')
    end
  end
  
  def test_pulling_dir_over_existing_files
    assert_nothing_raised do
      @ftp.pull_dir(@dst, '/')
      FileUtils.rm File.join(@dst, 'README')
      @ftp.pull_dir(@dst, '/')
      assert File.exist?(File.join(@dst, 'README'))
    end
  end
  
  def test_pulling_dir_with_deleting_files
    @ftp.pull_dir(@dst, '/')
    Net::FTP.ftp_src['/'].shift
    @ftp.pull_dir(@dst, '/', :delete => true)
    assert !File.exist?(File.join(@dst, 'README'))
  end
  
  def test_pulling_dir_with_not_deleting_files
    @ftp.pull_dir(@dst, '/')
    assert File.exist?(File.join(@dst, 'README'))
    Net::FTP.ftp_src['/'].shift
    @ftp.pull_dir(@dst, '/')
    assert File.exist?(File.join(@dst, 'README'))
  end
  
  protected
   def create_tmpname
      tmpname = ''
      char_list = ("a".."z").to_a + ("0".."9").to_a
			1.upto(20) { |i| tmpname << char_list[rand(char_list.size)] }
			return tmpname
    end
end
