quote do: sum(1, 2, 3)
# {:sum, [], [1, 2, 3]}

quote do: 1 + 2
# {:+, [context: Elixir, import: Kernel], [1, 2]}

quote do: %{1 => 2}
# {:%{}, [], [{1, 2}]}

quote do: x
# {:x, [], Elixir}

quote do: sum(1, 2 + 3, 4)
# {:sum, [], [1, {:+, [context: Elixir, import: Kernel], [2, 3]}, 4]}

Macro.to_string(quote do: sum(1, 2 + 3, 4))
# "sum(1, 2 + 3, 4)"

:sum         #=> Atoms
1.0          #=> Numbers
[1, 2]       #=> Lists
"strings"    #=> Strings
{key, value} #=> Tuples with two elements

inner = [3, 4, 5]
Macro.to_string(quote do: [1, 2, unquote(inner), 6])

inner = [3, 4, 5]
Macro.to_string(quote do: [1, 2, unquote_splicing(inner), 6])
