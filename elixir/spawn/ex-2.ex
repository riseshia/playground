defmodule Token do
  def greet(token, return_token) do
    receive do
      {sender, called} ->
        if called == token do
          IO.puts return_token
          send sender, {:ok, return_token}
          # greet(token, return_token)
        else
          msg = "What are you saying?"
          IO.puts msg
          send sender, {:ok, msg}
          # greet(token, return_token)
        end
      after 500 ->
        IO.puts "done"
    end
  end
end

fred = spawn(Token, :greet, ["fred", "betty"])
betty = spawn(Token, :greet, ["betty", "fred"])

send betty, {fred, "betty"}
send fred, {betty, "fred"}
