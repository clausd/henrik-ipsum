require 'rubygems'
# require 'sinatra'
require 'yaml'
require 'delegate'

# we're relying on simplistic ruby 1.8.7 handling of utf-8
class Node < SimpleDelegator
  attr_accessor :key, :count, :children, :model
  
  def initialize(thekey)
    self.key = thekey
    self.count = 0
    self.children = {}
    super(self.children)
  end
  
  def append(array)
    node = self
    node.count += 1
    a = array.clone
    if c = a.shift
      node[c] ||= Node.new(c)
      node[c].append(a)
    end
    self
  end
  
  def pick
    n = (rand*count).floor
    i = 0
    retval = nil
    self.children.each_value do |child|
      retval = child
      if i >= n
        return retval
      else
        i += child.count
      end
    end
    return retval
  end
  
end

class Ipsum
  
  def initialize(language = 'da')
    parsing = YAML::load_file("parsing.#{language}.yml")
    @upper_chars = parsing['upper'].split('')
    @lower_chars = parsing['lower'].split('')
    @stop_chars = parsing['stop'].split('')
    @letter_chars = @upper_chars + @lower_chars
    @accept_chars = @letter_chars + @stop_chars + parsing['accept'].split('') + ["\n", ' ', "\t", '.']
    @model = YAML::load_file("model.#{language}.yml") if File.exist?("model.#{language}.yml")
  end
  
  def accept(c)
    @accept_chars.index(c)
  end
  
  def to_lower(c)
    @upper_chars.index(c) ? @lower_chars[@upper_chars.index(c)] : c
  end
  
  def to_upper(c)
    @lower_chars.index(c) ? @upper_chars[@lower_chars.index(c)] : c
  end

  def letter(c)
    @letter_chars.index(c)
  end
  
  def stop(c)
    return @stop_chars.index(c)
  end

  def space(c)
    return @accept_chars.index(c) && @letter_chars.index(c).nil? && @stop_chars.index(c).nil?
  end
  
  def capitalize(word)
    word[0] = to_upper(word[0])
    word
  end

  def build_model(filename, depth = 5)
    root = Node.new(nil)
    chars = []
    scan_file(filename) do |c|
      chars << c
      while (chars.count > depth) do
        root.append(chars[0..4])
        chars.shift
      end
    end
    @model = root
  end

  def scan_file(filename, &block) 
    File.open(filename,'r') do |f|
      f.each do |l|
        scan_string(l, &block)
      end
    end
  end

  def scan_string(string)
    spaced = true
    string.split('').each do |c|
      if accept(c)
        c = to_lower(c)
        if space(c) 
          c = ' '
        else
          spaced = false
        end
        yield c if !spaced #only one space at a time
        if c == ' '
          spaced = true
        end
      end
    end
    nil
  end
  
  def gibberish(n)
    cap = true
    c = @model.pick
    out = [to_upper(c.key)]
    while out.length<n
      nk = c.pick
      c = nk.nil? ? @model.pick : nk
      c = to_upper(c) if cap
      out << c.key
      cap = false if letter(c)
      cap = true if stop(c)
      out << ' ' if stop(c)
    end
    return out.join('')
  end
  
end

# 
# get '/' do
#   @gibberish = Nordem.gibberish(100)
#   erb :index
# end
# 
# get '/:length' do
#   @gibberish = Nordem.gibberish(params[:length].to_i)
#   erb :index
# end
# 
# __END__
# @@index
# <html>
# <head>
# <meta http-equiv="Content-Type" content="text/html;charset=utf-8">
# </head>
# <body>
# <%= @gibberish %>
# </body>
# </html>