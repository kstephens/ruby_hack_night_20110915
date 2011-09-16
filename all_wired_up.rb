#!/usr/bin/env ruby
require 'pp'

class WiredUp
  attr_accessor :lines, :inputs

  SPACE = ' '.freeze

def c(x, y = nil)
  if Array === x
    y = x[1]
    x = x[0]
  end
  s = lines[y]
  if s
    if x >= 0 
      s = s[x, 1]
    else
      return nil
    end
  end
  s = s && (s.empty? ? nil : s)
  s = nil if s == SPACE
  s
end

# Find @.
def initial_turtle
  initial_turtle = nil
  turtle = [ 0, 0, -1, 0 ]
  lines.each do | line |
    if turtle[0] = line.index('@')
      initial_turtle = turtle
      break
    end
    turtle[1] += 1
  end
  initial_turtle or raise "Cannot find @ in\n#{lines * "\n"}"
end

def forward(turtle)
  [ turtle[0] + turtle[2], 
    turtle[1] + turtle[3],
    turtle[2],
    turtle[3],
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
  if true
    s = c(turtle)
    unless s == '-' or s == '|'
      pp [ :s=, s, :turtle=, turtle, :level=, @level ]
    end
  end
  result = _parse(turtle)
  @level -= 1
  result
end

def _parse turtle
  case s = c(turtle)
  when nil
    nil
  when '@'
    4.times do
      pp [ :turtle=, turtle ]
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
    "@input[#{v.inspect}]"
  when '-', '|'
    l_of  = forward(turn_left(turtle))
    r_of  = forward(turn_right(turtle))
    turn_c = (s == '-' ? '|' : '-')
    case
    when c(l_of) == turn_c
      turtle = l_of
    when c(r_of) == turn_c
      turtle = r_of
    else
      turtle = forward(turtle)
    end
    _parse(turtle)
  when 'O', 'A', 'X', 'N'
    right = parse(forward(turn_right(turtle)))
    left  = parse(forward(turn_left(turtle)))
    # pp [ level, s, turtle, left, right ]
    case s
    when 'O'
      "(#{left} or #{right})"
    when 'A'
      "(#{left} and #{right})"
    when 'X'
      "(#{left} != #{right})"
    when 'N'
      right = left if right == nil
      "(not #{right})"
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

def variables
  expr
  @variables ||= [ ]
end

def value(input = { })
  @input = input
  (@value ||=
    [ eval(expr) ]).first
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

verbose = false
verbose = true
until file.eof?
  wired_up = WiredUp.new
  wired_up.lines_from! file
  
  puts "======================================================" if verbose
  puts wired_up.lines * "\n" if verbose
  pp [ :variables, wired_up.variables ] unless wired_up.variables.empty?
  wired_up.inputs = { :a => true, :b => false, :c => true }
  result = wired_up.value
  pp [ :inputs, wired_up.inputs ] unless wired_up.variables.empty?
  pp [ :expr, wired_up.expr ]
  pp [ :result=, result ]
  
end

