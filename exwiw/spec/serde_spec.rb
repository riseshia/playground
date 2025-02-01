# frozen_string_literal: true

RSpec.describe Exwiw::Serde do
  class Config
    include Exwiw::Serde

    attribute :name, String
  end

  context "deserialize" do
    it "does not raise error" do
      expect {
        Config.from({ "name" => "config" })
      }.not_to raise_error
    end

    it "raises error" do
      expect {
        Config.from({ "name" => 111 })
      }.to raise_error(Exwiw::Serde::TypeError)
    end

    it "builds config correctly" do
      config = Config.from({ "name" => "config" })

      expect(config.name).to eq("config")
    end
  end

  context "serialize" do
    it "does not raise error" do
      expect {
        Config.to({ "name" => "config" }).to
      }.not_to raise_error
    end

    it "builds hash correctly" do
      config = Config.from({ "name" => "config" })

      expect(config.to).to eq({ "name" => "config" })
    end
  end
end
