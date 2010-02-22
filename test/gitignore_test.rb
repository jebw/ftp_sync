require 'test/unit'
require 'gitignore_parser'

class GitignoreTest < Test::Unit::TestCase
    
  def test_skips_blank_lines_in_gitignore
    gitignore = GitignoreParser::parse("\nfoo.txt\n\n")
    assert gitignore.ignore?('foo.txt')
  end
  
  def test_skips_commented_lines_in_gitignore
    gitignore = GitignoreParser::parse("foo.txt\n#bar.txt\n")
    assert gitignore.ignore?('foo.txt')
    assert !gitignore.ignore?('bar.txt')
  end
  
  def test_filename_ignore
    gitignore = GitignoreParser::parse('foo.txt')
    assert gitignore.ignore?('foo.txt')
    assert gitignore.ignore?('foo/foo.txt')
    assert gitignore.ignore?('foo/bar/foo.txt')
    assert !gitignore.ignore?('bar.txt')
    assert !gitignore.ignore?('foo/bar.txt')
    assert !gitignore.ignore?('barfoo.txt')
  end
  
  def test_simple_ignore
    gitignore = GitignoreParser::parse("*.txt\n")
    assert gitignore.ignore?('foo.txt')
    assert gitignore.ignore?('nested/foo.txt')
    assert !gitignore.ignore?('foo.jpg')
    assert !gitignore.ignore?('foo_txt')
    assert !gitignore.ignore?('foo.txt.jpg')
  end
  
  def test_combined_ignore
    gitignore = GitignoreParser::parse("*.txt\n*.jpg\n")
    assert gitignore.ignore?("foo.txt")
    assert gitignore.ignore?("foo.jpg")
    assert gitignore.ignore?("foo.jpg.txt")
    assert !gitignore.ignore?("foo.doc")
  end
  
  def test_path_only_ignore
    gitignore = GitignoreParser::parse("doc/")
    assert gitignore.ignore?("doc/foo.txt")
    assert gitignore.ignore?("src/doc/foo.txt")
    assert !gitignore.ignore?("src/foo.txt")
    assert !gitignore.ignore?("doc")
  end
  
  def test_simple_glob_ignore
    gitignore = GitignoreParser::parse("doc/*.txt")
    assert gitignore.ignore?("doc/foo.txt")
    assert !gitignore.ignore?("src/doc/foo.txt")
    assert !gitignore.ignore?("src/foo.txt")
  end
  
  def test_path_only_glob_ignore
    gitignore = GitignoreParser::parse("doc/*")
    assert gitignore.ignore?("doc/html/index.html")
    assert gitignore.ignore?("doc/html")
    assert gitignore.ignore?("doc/pdf")
    assert gitignore.ignore?("doc/pdf/index.pdf")
    assert gitignore.ignore?("doc/index.html")
    assert !gitignore.ignore?("src/index.html")
    assert !gitignore.ignore?("src/doc/index.html")
  end
  
  def test_path_and_file_glob
    gitignore = GitignoreParser::parse("foo/**/*.txt")
    assert gitignore.ignore?("foo/bar/hello.txt")
    assert !gitignore.ignore?("foo/bar/hello.html")
    assert !gitignore.ignore?("foo/bar")
  end
  
end