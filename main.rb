require 'optparse'

opts = {
    'size' => 10,
    'sleep_step' => 0.05,
    'sleep_game' => 2.0,
}
OptionParser.new do |opt|
  opt.on('--size 10') { |v| opts['size'] = v.to_i }
  opt.on('--sleep-step 0.05') { |v| opts['sleep_step'] = v.to_f }
  opt.on('--sleep-game 2') { |v| opts['sleep_game'] = v.to_f }
end.parse!(ARGV)

def init(n)
  game = []
  n.times.each do |i|
    game[i] = []
    n.times.each { |j|
      game[i] << ['□', '■'].sample
    }
  end
  [game, Marshal.load(Marshal.dump(game))]
end

def disp(game)
  # game.map(&:join).join("\n")
  game.map { |row| row.join(' ') }.join("\n")
end

size = opts['size']
game, oldgame = init(size)
nstep = 0
ngame = 0
record_game = 0
record_steps = 0

def step(game, oldgame, nstep)
  newgame = Marshal.load(Marshal.dump(game))
  ilen = game.size-1
  jlen = game[0].size-1

  0.upto(game.size-1) do |i|
    0.upto(game[i].size-1) do |j|

      env = []

      env << game[i-1][j-1] if i != 0 && j != 0
      env << game[i  ][j-1] if j != 0
      env << game[i+1][j-1] if i != ilen && j != 0

      env << game[i-1][j  ] if i != 0
      env << game[i+1][j  ] if i != ilen

      env << game[i-1][j+1] if i != 0 && j != jlen
      env << game[i  ][j+1] if j != jlen
      env << game[i+1][j+1] if i != ilen && j != jlen

      if game[i][j] == '■' # live
        if env.count('■') == 2 || env.count('+') == 3 # live
          newgame[i][j] = '■'
        elsif env.count('■') <= 1 # depopulation
          newgame[i][j] = '□'
        elsif env.count('■') >= 4 # overpopulation
          newgame[i][j] = '□'
        end
      else # dead
        if env.count('■') == 3 # birth
          newgame[i][j] = '■'
        end
      end
    end
  end

  if game.map(&:join).join.count('■') == 0
    # Dead world.
    warn "Dead world. Game Over."
    raise
  elsif game.map(&:join).join == newgame.map(&:join).join
    # no change. world is stop. game over.
    warn "Frozen. Game Over."
    raise
    # raise "Game Over."
  elsif oldgame.map(&:join).join == newgame.map(&:join).join
    # 千日手
    warn "千日手. Game Over."
    raise
    # raise "千日手."
  else
    [newgame, Marshal.load(Marshal.dump(game)), nstep+1]
  end
end

ngame = 1
loop do
  game, oldgame, nstep = step(game, oldgame, nstep)
  puts "\e[H\e[2J"
  puts disp(game)
  puts "#{size}x#{size}\tgame:\t#{'% 3d' % ngame} step: #{'% 3d' % nstep}"
  puts "\trecord:\t#{'% 3d' % record_steps} steps (game ##{record_game})"
  sleep opts['sleep_step']
rescue
  if nstep > record_steps
    record_game = ngame
    record_steps = nstep
  end
  game, oldgame = init(size)
  nstep = 0
  ngame += 1
  sleep opts['sleep_game']
  redo
end