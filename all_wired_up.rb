#!/usr/bin/env ruby
require 'pp'

class WiredUp
  attr_accessor :lines, :inputs
  attr_accessor :verbose

  SPACE = ' '.freeze

def c(x, y = nil)
  x, y = *x if Array === x
  if s = lines[y] and 0 <= x and x < s.size
    s = s[x, 1]
    s = nil if s.empty? || s == SPACE
  end
  s
end

# Find @.
def initial_turtle
  turtle = [ 0, 0, -1, 0 ]
  initial_turtle = lines.each do | line |
    break turtle if turtle[0] = line.index('@')
    turtle[1] += 1
  end
  initial_turtle or raise "Cannot find @ in\n#{lines * "\n"}"
end

def forward(turtle)
  [ turtle[0] + turtle[2], # x
    turtle[1] + turtle[3], # y
    turtle[2],             # dx
    turtle[3],             # dy
  ]
end

def turn_right(turtle)
  [ turtle[0],
    turtle[1],
    - turtle[3],
    turtle[2],
  ]
end

def turn_left(turtle)
  [ turtle[0],
    turtle[1],
    turtle[3],
   - turtle[2],
  ]
end

def left(turtle)
  [ turtle[0],
    turtle[1],
    -1,
    0,
  ]
end

# Returns Ruby expression.
def parse turtle = nil
  turtle ||= initial_turtle
  @level ||= 0
  @level += 1
  if verbose
    s = c(turtle)
    unless s == '-' or s == '|'
      pp [ :s=, s, :turtle=, turtle, :level=, @level ]
    end
  end
  result = _parse(turtle)
  if verbose
    unless s == '-' or s == '|'
      pp [ :s=, s, :turtle=, turtle, :level=, @level, :result=, result ]
    end
  end
  @level -= 1
  result
end

def _parse turtle
  case s = c(turtle)
  when nil
    nil
  when '@'
    4.times do
      # pp [ :turtle=, turtle ]
      if c(new_turtle = forward(turtle))
        return _parse(new_turtle)
      end
      turtle = turn_left(turtle)
    end
    raise "Cannot go anywhere from #{turtle.inspect}"
  when '0'
    false
  when '1'
    true
  when /[a-z]/
    v = s.to_sym
    @variables ||= [ ]
    @variables << v unless @variables.include?(v)
    "(! ! @inputs[#{v.inspect}])"
  when '-', '|'
    left   = forward(turn_left(turtle))
    right  = forward(turn_right(turtle))
    turn_c = (s == '-' ? '|' : '-')
    turtle = case
    when c(left) == turn_c
      left
    when c(right) == turn_c
      right
    else
      forward(turtle)
    end
    _parse(turtle)
  when 'O', 'A', 'X', 'N'
    right = parse(forward(turn_right(turtle)))
    left  = parse(forward(turn_left(turtle)))
    # pp [ level, s, turtle, left, right ]
    case s
    when 'O'
      "(#{left} || #{right})"
    when 'A'
      "(#{left} && #{right})"
    when 'X'
      "(#{left} != #{right})"
    when 'N'
      right = left if right == nil
      "(! #{right})"
    else
      raise
    end
  else
    raise "Error at #{s.inspect} #{turtle.inspect}"
  end
end

def expr
  @expr ||=
    begin
      @level = 0
      parse
    end
end

def value_method
  @value_method ||= 
    begin
      instance_eval <<END
def _value
  #{expr}
end
END
      :_value
    end
end

def variables
  expr
  @variables ||= [ ]
end

def value(inputs = nil)
  @inputs = inputs if inputs
  send(value_method)
end

def lines_from! file
  @lines = [ ]
  until file.eof?
    line = file.readline
    if line && line =~ /^\s*$/
      if lines.empty?
        next
      else
        break
      end
    end
    line.chomp!
    lines << line
  end

  # pp [ :input_lines=, lines ]

  self
end

end

file = File.open(ARGV[0])

verbose = ENV['verbose']
#verbose = true
until file.eof?
  wired_up = WiredUp.new
  wired_up.lines_from! file
  wired_up.verbose = verbose

  if verbose
    puts "\n======================================================\n\n" 
    puts wired_up.lines * "\n"
  end
  wired_up.inputs = { :a => true, :b => false, :c => true }
  if verbose
    pp [ :expr, wired_up.expr ]
    unless wired_up.variables.empty?
      pp [ :variables, wired_up.variables ] 
      pp [ :inputs, wired_up.inputs ]
    end
  end
  result = wired_up.value
  pp [ :result=, result ] if verbose
  puts result ? "on" : "off"
end

