class GitignoreParser
  class << self
    def parse(gitignore)
      new(gitignore)
    end
  end

  def initialize(gitignore)
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
    @regex =~ path || @globs.any? {|g| File.fnmatch(g, path) }
  end

end