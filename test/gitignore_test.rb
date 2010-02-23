require 'test/unit'
require 'gitignore_parser'
require 'tmpdir'

class GitignoreTest < Test::Unit::TestCase
  
  def setup
    @gitdir = Dir.tmpdir
  end
    
  def test_skips_blank_lines_in_gitignore
    create_git_ignore "\nfoo.txt\n\n"
    assert GitignoreParser::parse(@gitdir).ignore?(File.join(@gitdir, 'foo.txt'))
  end
  
  def test_skips_commented_lines_in_gitignore
    create_git_ignore "foo.txt\n#bar.txt\n"
    gitignore = GitignoreParser::parse(@gitdir)
    assert gitignore.ignore?(File.join(@gitdir, 'foo.txt'))
    assert !gitignore.ignore?(File.join(@gitdir, 'bar.txt'))
  end
  
  def test_filename_ignore
    create_git_ignore 'foo.txt'
    gitignore = GitignoreParser::parse(@gitdir)
    assert gitignore.ignore?(File.join(@gitdir, 'foo.txt'))
    assert gitignore.ignore?(File.join(@gitdir, 'foo/foo.txt'))
    assert gitignore.ignore?(File.join(@gitdir, 'foo/bar/foo.txt'))
    assert !gitignore.ignore?(File.join(@gitdir, 'bar.txt'))
    assert !gitignore.ignore?(File.join(@gitdir, 'foo/bar.txt'))
    assert !gitignore.ignore?(File.join(@gitdir, 'barfoo.txt'))
  end
  
  def test_simple_ignore
    create_git_ignore "*.txt\n"
    gitignore = GitignoreParser::parse(@gitdir)
    assert gitignore.ignore?(File.join(@gitdir, 'foo.txt'))
    assert gitignore.ignore?(File.join(@gitdir, 'nested/foo.txt'))
    assert !gitignore.ignore?(File.join(@gitdir, 'foo.jpg'))
    assert !gitignore.ignore?(File.join(@gitdir, 'foo_txt'))
    assert !gitignore.ignore?(File.join(@gitdir, 'foo.txt.jpg'))
  end
  
  def test_combined_ignore
    create_git_ignore "*.txt\n*.jpg\n"
    gitignore = GitignoreParser::parse(@gitdir)
    assert gitignore.ignore?(File.join(@gitdir, "foo.txt"))
    assert gitignore.ignore?(File.join(@gitdir, "foo.jpg"))
    assert gitignore.ignore?(File.join(@gitdir, "foo.jpg.txt"))
    assert !gitignore.ignore?(File.join(@gitdir, "foo.doc"))
  end
  
  def test_path_only_ignore
    create_git_ignore "doc/"
    gitignore = GitignoreParser::parse(@gitdir)
    assert gitignore.ignore?(File.join(@gitdir, "doc/foo.txt"))
    assert gitignore.ignore?(File.join(@gitdir, "src/doc/foo.txt"))
    assert !gitignore.ignore?(File.join(@gitdir, "src/foo.txt"))
    assert !gitignore.ignore?(File.join(@gitdir, "doc"))
  end
  
  def test_simple_glob_ignore
    create_git_ignore "doc/*.txt"
    gitignore = GitignoreParser::parse(@gitdir)
    assert gitignore.ignore?(File.join(@gitdir, "doc/foo.txt"))
    assert !gitignore.ignore?(File.join(@gitdir, "src/doc/foo.txt"))
    assert !gitignore.ignore?(File.join(@gitdir, "src/foo.txt"))
  end
  
  def test_path_only_glob_ignore
    create_git_ignore "doc/*"
    gitignore = GitignoreParser::parse(@gitdir)
    assert gitignore.ignore?(File.join(@gitdir, "doc/html/index.html"))
    assert gitignore.ignore?(File.join(@gitdir, "doc/html"))
    assert gitignore.ignore?(File.join(@gitdir, "doc/pdf"))
    assert gitignore.ignore?(File.join(@gitdir, "doc/pdf/index.pdf"))
    assert gitignore.ignore?(File.join(@gitdir, "doc/index.html"))
    assert !gitignore.ignore?(File.join(@gitdir, "src/index.html"))
    assert !gitignore.ignore?(File.join(@gitdir, "src/doc/index.html"))
  end
  
  def test_path_and_file_glob
    create_git_ignore "foo/**/*.txt"
    gitignore = GitignoreParser::parse(@gitdir)
    assert gitignore.ignore?(File.join(@gitdir, "foo/bar/hello.txt"))
    assert !gitignore.ignore?(File.join(@gitdir, "foo/bar/hello.html"))
    assert !gitignore.ignore?(File.join(@gitdir, "foo/bar"))
  end
  
  def teardown
    FileUtils.rm_rf @gitdir
  end
  
  protected
  
    def create_git_ignore(ignore_content)
      File.open File.join(@gitdir, '.gitignore'), 'w' do |f|
        f.write ignore_content
      end
    end
  
end