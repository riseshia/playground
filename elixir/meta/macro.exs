defmodule Unless do
  def fun_unless(clause, expression) do
    if(!clause, do: expression)
  end

  defmacro macro_unless(clause, expression) do
    quote do
      if(!unquote(clause), do: unquote(expression))
    end
  end
end

defmodule Hygiene do
  defmacro no_interference do
    quote do: a = 1
  end

  defmacro interference do
    quote do: var!(a) = 1
  end
end

defmodule HygieneTest do
  def go1 do
    require Hygiene
    a = 13
    Hygiene.no_interference
    a
  end

  def go2 do
    require Hygiene
    a = 13
    Hygiene.interference
    a
  end
end

defmodule Sample do
  defmacro initialize_to_char_count(variables) do
    Enum.map variables, fn(name) ->
      var = Macro.var(name, nil)
      length = name |> Atom.to_string |> String.length
      quote do
        unquote(var) = unquote(length)
      end
    end
  end

  def run do
    initialize_to_char_count [:red, :green, :yellow]
    [red, green, yellow]
  end
end

# BAD

defmodule MyModule do
  defmacro my_macro(a, b, c) do
    quote do
      do_this(unquote(a))
      ...
      do_that(unquote(b))
      ...
      and_that(unquote(c))
    end
  end
end

# GOOD

defmodule MyModule do
  defmacro my_macro(a, b, c) do
    quote do
      # Keep what you need to do here to a minimum
      # and move everything else to a function
      do_this_that_and_that(unquote(a), unquote(b), unquote(c))
    end
  end

  def do_this_that_and_that(a, b, c) do
    do_this(a)
    ...
    do_that(b)
    ...
    and_that(c)
  end
end