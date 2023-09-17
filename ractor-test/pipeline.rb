# pipeline with yield/take
r1 = Ractor.new do
  'r1'
end

r2 = Ractor.new r1 do |r1|
  r1.take + 'r2'
end

r3 = Ractor.new r2 do |r2|
  r2.take + 'r3'
end

p r3.take #=> 'r1r2r3'

# pipeline with send/receive
r3 = Ractor.new Ractor.current do |cr|
  cr.send Ractor.receive + 'r3'
end

r2 = Ractor.new r3 do |r3|
  r3.send Ractor.receive + 'r2'
end

r1 = Ractor.new r2 do |r2|
  r2.send Ractor.receive + 'r1'
end

r1 << 'r0'
p Ractor.receive #=> "r0r1r2r3"
