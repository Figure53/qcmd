# slide the playback rate up and down
require 'osc-ruby'
c = OSC::Client.new 'localhost', 53000

# first cue
cue_number = 1

# pause between OSC messages. if this is much below 0.05 it'll just get weird
sleep_time = 0.05

# more steps means a longer slide
steps = 100

# how high should rate peak
max_rate = 2.0

10.times do
  # start at 1 to avoid sending 0.0 to rate
  (1..steps).each do |n|
    c.send(OSC::Message.new("/cue/#{ cue_number }/rate", n / (steps / max_rate)))
    sleep(sleep_time)
  end

  (1..steps).each do |n|
    c.send(OSC::Message.new("/cue/#{ cue_number }/rate", 2.0 - (n / (steps / max_rate))))
    sleep(sleep_time)
  end
end
