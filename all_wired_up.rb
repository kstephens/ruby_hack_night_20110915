#!/usr/bin/env ruby
require 'pp'

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
  s && (s.empty? ? nil : s)
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

=begin
  unless s == '-'
    pp [ :turtle=, turtle, :level=, level ]
    pp [ :s=, s ] 
  end
=end

  result =
  case s
  when nil, ' '
    nil
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
  when 'O', 'A', 'X', 'N'
    right = parse(forward(turn_right(turtle)), level + 1)
    left  = parse(forward(turn_left(turtle)),  level + 1)
    # pp [ level, s, turtle, left, right ]
    case s
    when 'O'
      left or right
    when 'A'
      left and right
    when 'X'
      left != right
    when 'N'
      right = left if left == nil
      not right
    else
      raise
    end
  else
    raise "Error at #{s.inspect} #{turtle.inspect}"
  end

  # pp [ :result=, result, :level=, level]
  result
end

file = File.open(ARGV[0])

until file.eof?
  lines = [ ]
  until file.eof?
    line = file.readline
    # pp [ :line=, line ]
    break if line =~ /^\s*$/
    line.chomp!
    lines << line
  end

  # pp [ :input_lines=, lines ]

  $lines = lines
  # Find @.
  turtle = [ 0, 0, -1, 0 ]
  $lines.each do | line |
    if turtle[0] = line.index('@')
      break
    end
    turtle[1] += 1
  end
  
  puts "======================================================"
  puts lines * "\n"
  pp [ :turtle, turtle ]
  result = parse(turtle)
  pp [ :result=, result ]
  
end

