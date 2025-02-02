# frozen_string_literal: true

RSpec.describe Exwiw::Serde do
  class Database
    include Exwiw::Serde

    attribute :adapter, String
  end

  class Table
    include Exwiw::Serde

    attribute :name, String
    attribute :comment, optional(String)
  end

  class Config
    include Exwiw::Serde

    attribute :name, String
    attribute :version, Integer
    attribute :database, Database
    attribute :tables, [Table]
  end

  context "deserialize" do
    it "does not raise error" do
      expect {
        Config.from_hash({
          "name" => "config",
          "version" => 1,
          "database" => {
            "adapter" => "mysql"
          },
          "tables" => [
            { "name" => "users" },
            { "name" => "posts", "comment" => "This is a comment" }
          ]
        })
      }.not_to raise_error
    end

    # it "raises error" do
    #   expect {
    #     Config.from({
    #       "name" => "config",
    #       "database" => {
    #         "adapter" => "mysql"
    #       },
    #       "tables" => [
    #         { "name" => "users" },
    #         { "name" => "posts", "comment" => "This is a comment" }
    #       ]
    #     })
    #   }.to raise_error(Exwiw::Serde::RequiredAttributeError)
    # end
    #
    # it "builds config correctly" do
    #   config = Config.from({
    #     "name" => "config",
    #     "version" => 1,
    #     "database" => {
    #       "adapter" => "mysql"
    #     },
    #     "tables" => [
    #       { "name" => "users" },
    #       { "name" => "posts", "comment" => "This is a comment" }
    #     ]
    #   })
    #
    #   expect(config.name).to eq("config")
    #   expect(config.version).to eq(1)
    #   expect(config.database.adapter).to eq("mysql")
    #   expect(config.tables.first.name).to eq("users")
    #   expect(config.tables.first.comment).to be_nil
    #   expect(config.tables.last.name).to eq("posts")
    #   expect(config.tables.last.comment).to eq("This is a comment")
    # end
  end

  # context "serialize" do
  #   it "does not raise error" do
  #     expect {
  #       Config.to({ "name" => "config" }).to
  #     }.not_to raise_error
  #   end

  #   it "builds hash correctly" do
  #     config = Config.from({ "name" => "config" })

  #     expect(config.to).to eq({ "name" => "config" })
  #   end
  # end
end
