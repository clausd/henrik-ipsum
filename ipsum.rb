require 'rubygems'
# require 'sinatra'
require 'yaml'
require 'delegate'

# we're relying on simplistic ruby 1.8.7 handling of utf-8
class Node < SimpleDelegator
  attr_accessor :key, :count, :children
  
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
    p n
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
    @letter_chars = parsing['letters'].split('')
    @lower_chars = parsing['letters_lower'].split('')
    @stop_chars = parsing['sentence_end'].split('')
    @accept_chars = @letter_chars + @stop_chars + parsing['accept'].split('')
    @model = YAML::load_file("model.#{language}.yml") if File.exist?("model.#{language}.yml")
  end
  
  # Should do binary search but enough for now....
  def self.draw_from_weighted_array(a)
      # p a
      r = rand
      if a.length == 0
        return nil
      end
      i = a.length-1
      while i>0 && a[i][1] > r 
        i -= 1
      end
      return a[i][0]
  end

  def self.build_weighted_array(occurences)
    sum = 0.0
    occurences.each_value {|v| sum += v}
    ret = []
    dist = 0
    occurences.each_pair {|k,v| ret.push([k,dist]); dist += v/sum}
    return ret
  end

  def accept(c)
    @accept_chars.index(c)
  end
  
  def to_lower(c)
    @letter_chars.index(c) ? @lower_chars[@letter_chars.index(c)] : c
  end

  def stop(c)
    return @stop_chars.index(c)
  end
  
  def space(c)
    return @@whitespace_chars[c]
  end

  def count_string(string)
    string.unpack('U*').reduce({}) {|occ, c| occ[c] = occ[c].to_i + 1 if accept(c)}
  end

  def count_file(filename) 
    occ = {}
    last = 0
    File.open(filename,'r') do |f|
      f.each do |l|
        l.unpack('U*').each do |c|
          if accept(c)
            if space(c) 
              c = 32
              if space(last.last)
                next
              end
            end
            if last != 0
              occ[last] ||= {}
              occ[last][c] = occ[last][c].to_i + 1
            end
            last = c
          end
        end
      end
    end
    return occ
  end
 
  def self.build_stats(filename)
    occ = count_file(filename)
    occ.each_key do |k|
      occ[k] = build_weighted_array(occ[k])
    end
    return occ
  end
  
  def self.gibberish(n)
    c = draw_from_weighted_array(@@bigrams[46])
    out = []
    out.push(c)
    while out.length<n
      while !stop(c)
        # p c 
        # p @@bigrams[c]
        c = draw_from_weighted_array(@@bigrams[c])
        out.push(c)
      end
      # out.push(46)
      c = draw_from_weighted_array(@@bigrams[46])
      out.push(c)
    end
    return out.pack('U*')
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