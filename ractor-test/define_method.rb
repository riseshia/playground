def just_method
  1
end

module L
  module_function

  def normal
    1
  end

  define_method(:dmethod) { 1 }

  define_method(:imethod, instance_method(:normal))
end

L.normal
L.dmethod
L.imethod
Ractor.new { L.normal }.take
Ractor.new { L.dmethod }.take
Ractor.new { L.imethod }.take
