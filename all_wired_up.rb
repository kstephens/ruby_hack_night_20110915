#!/usr/bin/env ruby
require 'pp'

file = File.open(ARGV[0])
lines = [ ]
until file.eof?
  line = file.readline
  pp [ :line=, line ]
  break if line =~ /^\s*$/
  line.chomp!
  lines << line
end

=begin
lines.each { | l | l.sub(/#.*/, '') }
#lines.each { | l | l.gsub!(/[^01AOXN@]/i, ''); }
lines.each { | l | l.gsub!(/[^01AOXN]/i, ''); }
lines.reject! { | l | l.empty? }
=end
pp [ :input_lines=, lines ]

$lines = lines
def c(x, y = nil)
  if Array === x
    y = x[1]
    x = x[0]
  end
  s = $lines[y]
  if s 
    if x >= 0 
      s = s[x, 1]
    else
      return nil
    end
  end
  s.empty? ? nil : s
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

# returns evaluated result
def parse turtle, level = 0
  s = c(turtle)

  unless s == '-'
    pp [ :turtle=, turtle, :level=, level ]
    pp [ :s=, s ] 
  end

  result =
  case s
  when '@'
    parse(forward(left(turtle)), level + 1)
  when '0'
    false
  when '1'
    true
  when '-'
    parse(forward(turtle), level)
  when '|'
    l_of  = forward(turn_left(turtle))
    r_of  = forward(turn_right(turtle))
    case
    when c(l_of) == '-'
      turtle = l_of
    when c(r_of) == '-'
      turtle = r_of
    else
      turtle = forward(turtle)
    end
    parse(turtle, level)
  when 'O'
    right = parse(forward(turn_right(turtle)), level + 1)
    left  = parse(forward(turn_left(turtle)),  level + 1)
    pp [ level, :or, turtle, left, right ]
    left or right
  when 'A'
    right = parse(forward(turn_right(turtle)), level + 1)
    left  = parse(forward(turn_left(turtle)),  level + 1)
    pp [ level, :and, left, right ]
    left and right
  when 'X'
    right = parse(forward(turn_right(turtle)), level + 1)
    left  = parse(forward(turn_left(turtle)),  level + 1)
    pp [ level, :xor, left, right ]
    left != right
  when 'N'
    right = parse(forward(turn_right(turtle)), level + 1)
    pp [ level, :not, right ]
    not right
  else
    raise "Error at #{s.inspect} #{turtle.inspect}"
  end

  pp [ :result=, result, :level=, level]
  result
end

# Find @.
turtle = [ 0, 0, -1, 0 ]
$lines.each do | line |
  if turtle[0] = line.index('@')
    break
  end
  turtle[1] += 1
end

pp [ :turtle, turtle ]
result = parse(turtle)
pp [ :result=, result ]


