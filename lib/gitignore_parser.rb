class GitignoreParser
  class << self
    def parse(gitpath)
      new(gitpath)
    end
  end

  def initialize(gitpath)
    @gitpath = gitpath
    
    ignore_file = File.join(@gitpath, '.gitignore')
    gitignore = ".git\n"
    gitignore << File.read(ignore_file) if File.exist?(ignore_file)
    
    @globs = []
    rx = gitignore.split("\n").map do |i|
      i.strip!
      if i == '' or i.slice(0,1) == '#'
        nil
      elsif not i.include?('*')
        if i.slice(-1,1) == '/'
          i
        else
          "^#{i}|\/#{i}"
        end
      else
        @globs << i
        nil
      end
    end.compact.join("|")
    @regex = Regexp.new(rx) unless rx == ''
  end
  
  def ignore?(path)
    raise NotAbsolutePathError unless path.slice(0, 1) == '/'
    path.gsub! %r{^#{Regexp.escape(@gitpath)}\/}, ''
    @regex =~ path || @globs.any? {|g| File.fnmatch(g, path) }
  end

end

class NotAbsolutePathError < StandardError
  def initialize
    super("Supplied path is not an absolute path")
  end  
end
