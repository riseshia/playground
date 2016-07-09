defmodule Maxrot do

  def max_rot(num) do
    Integer.undigits(max_rot([], Integer.digits(num)))
  end

  def max_rot(fixed, [num]), do: fixed ++ [num]
  def max_rot(fixed, rest) do
    [hd1, hd2|tl] = rest
    new_fixed = fixed ++ [hd2]
    new_rest = tl ++ [hd1]
    
    max(max_rot(new_fixed, new_rest), fixed ++ rest)
  end

end

