defmodule MyList do
  def sum(list), do: _sum(list)
  defp _sum([]), do: 0
  defp _sum([h|t]), do: _sum(t) + h

  def mapsum(list, func), do: _mapsum(list, 0, func)
  defp _mapsum([], value, _func), do: value
  defp _mapsum([head|tail], value, func) do
    _mapsum(tail, func.(head), func) + value
  end

  def max(list) do
    [h|_] = list
    _max(list, h)
  end
  defp _max([], max), do: max
  defp _max([h|t], max) when h > max, do: _max(t, h)
  defp _max([_h|t], max), do: _max(t, max)

  def caesar(list, n), do: _caesar(list, n)
  defp _caesar([], _n), do: []
  defp _caesar([h|t], n) when h + n <= ?z, do: [h + n|_caesar(t, n)]
  defp _caesar([h|t], n), do: [h + n - 26|_caesar(t, n)]

  def span(to, to), do: [to]
  def span(from, to), do: [from|span(from+1, to)]
end

defmodule MyEnum do
  def all?([], _func), do: true
  def all?([h|t], func), do: func.(h) and all?(t, func)

  def each([], _f), do: []
  def each([h|t], f), do: [f.(h)|each(t, f)]
  # each, filter, split, take

  def filter([], _func), do: []
  def filter([h|t], f) do
    if f.(h) do
      [h, filter(t, f)]
    else
      filter(t, f)
    end
  end

  def flatten([]), do: []
  def flatten([h|t]), do: flatten(h) ++ flatten(t)
  def flatten(h), do: [h]
  # MyEnum.flatten([1, [2, 3, [4] ], 5, [[[6]]]])
end

defmodule MyGen do
  def primes([1]), do: []
  def primes([2]), do: [2]
  def primes(n) do
    for x <- MyList.span(2, n), is_prime?(x), do: x
  end

  def is_prime?(1), do: false
  def is_prime?(2), do: true
  def is_prime?(n) when rem(n, 2) == 0, do: false
  def is_prime?(n) do
    !Enum.any?(MyList.span(2, n-1), &(rem(n, &1) == 0))
  end

  def apply_tax(list) do
    tax_rates = [ NC: 0.075, TX: 0.08 ]

    for order <- list do
      if tax_rates[order[:ship_to]] do
        order ++ [{:net_plus_sales, tax_rates[order[:ship_to]] * order[:net_amount]}]
      else
        order
      end
    end
  end
end

defmodule MS do
  def ascii?(list), do: Enum.all?(list, &(&1 in ?\s..?~))
  def anagram?(word1, word2) do
    Enum.sort(word1) == Enum.sort(word2)
  end

  def number?(list), do: Enum.all?(list, &(&1 in ?0..?9))

  def calculate(clist) do
    [left, operator, right] = Enum.filter(clist, &(&1 != ?\s)) |> group([])
    if number?(left) and number?(right) do
      left_int = to_i(left)
      right_int = to_i(right)
      oper_func = get_operator(operator)

      # _calculate(left_int, operator, right_int)
      oper_func.(left_int, right_int)
    else
      0
    end
  end

  def _calculate(a, ?+, b), do: a + b
  def _calculate(a, ?-, b), do: a - b
  def _calculate(a, ?*, b), do: a * b
  def _calculate(a, ?/, b), do: a / b

  def group([], _) do
    # Fail
  end
  def group([h|t], left_side) when h in '+-*/', do: [left_side, h, t]
  def group([h|t], left_side), do: group(t, left_side ++ [h])

  def get_operator(?+), do: &(&1 + &2)
  def get_operator(?-), do: &(&1 - &2)
  def get_operator(?*), do: &(&1 * &2)
  def get_operator(?/), do: &(&1 / &2)

  def to_i(clist) do
    clist |> Enum.reduce(0, fn(x, acc) -> (x - ?0) + acc * 10 end)
  end

  def rjust_offset(max, word) do
    div(max + String.length(word), 2)
  end

  def center(list) do
    max_length = list |> Enum.map(&(String.length(&1))) |> Enum.max
    Enum.each(list, fn(word) ->
      len = rjust_offset(max_length, word)
      IO.puts String.rjust(word, len)
    end)
  end
end
