require "rack"

class App
  def call(env) # 引数は使ってない

    # レスポンスボディー（配列の形にする）
    body = ["Now #{ Time.now }"]

    # ステータス，ヘッダー，ボディーの三つ組を返す
    [200, {"Conent-Type" => "text/plain"}, body]
  end
end

Rack::Server.new(app: App.new).start
