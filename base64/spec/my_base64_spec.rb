require_relative "../lib/my_base64"

RSpec.describe MyBase64 do
  describe "#encode64" do
    {
      "" => "",
      "foob" => "Zm9vYg==",
      "fooba" => "Zm9vYmE=",
      "foobar" => "Zm9vYmFy"
    }.each do |passed_str, encoded_str|
      it "returns '#{encoded_str}' from '#{passed_str}'" do
        expect(MyBase64.encode64(passed_str)).to eq(encoded_str)
      end
    end
  end

  describe "#decode64" do
    {
      "" => "",
      "Zm9vYg==" => "foob",
      "Zm9vYmE=" => "fooba",
      "Zm9vYmFy" => "foobar",
    }.each do |encoded_str, origin_str|
      it "returns '#{encoded_str}' from '#{origin_str}'" do
        expect(MyBase64.decode64(encoded_str)).to eq(origin_str)
      end
    end
  end
end
