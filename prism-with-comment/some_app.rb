class SomeApp
  def initialize(
    name #:: String
  )
    @name = name
  end

  def name #:: String
    @name
  end

  def update_name(
    &block #:: Proc
  ) #:: String
    @name = block.call(@name)
  end
end