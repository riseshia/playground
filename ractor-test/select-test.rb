r1 = Ractor.new do
  d = 'r1'
  p d.object_id
  d
end

r, obj = Ractor.select(r1)
r == r1 and obj == 'r1' #=> true
p obj.object_id
