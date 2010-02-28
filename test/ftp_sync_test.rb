require 'rubygems'
require 'test/unit'
require 'ftp_sync'
require 'tmpdir'

class Ignore
  def ignore?(p); p == 'ignore' ? true : false; end
end

class FtpSyncTest < Test::Unit::TestCase
  
  def setup
    @dst = Dir.tmpdir
  end
  
  def teardown
    FileUtils.rm_rf @dst
  end
  
  def test_can_initialize_with_params
    ftp = FtpSync.new('localhost', 'testuser', 'testpass')
    assert_equal 'localhost', ftp.server
    assert_equal 'testuser', ftp.user
    assert_equal 'testpass', ftp.password
  end
  
  def test_can_set_verbose
    ftp = FtpSync.new('localhost', 'testuser', 'testpass')
    ftp.verbose = true
    assert_equal true, ftp.verbose
    ftp.verbose = false
    assert_equal false, ftp.verbose  
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
    ftp = FtpSync.new('test.server', 'user', 'pass')
    ftp.pull_files(@dst, '/', ['README', 'fileA' ])
    assert File.exist?(File.join(@dst, 'README'))
  end
  
  def test_pulling_unknown_files
    assert_raise Net::FTPPermError do
      ftp = FtpSync.new('test.server', 'user', 'pass')
      ftp.pull_files(@dst, '/', ['unknown' ])
    end
  end  
end
