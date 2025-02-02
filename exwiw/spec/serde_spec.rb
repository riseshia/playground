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

    attribute :table_names, array(String)
  end

  describe "deserialize" do
    context "simple case" do
      let(:database_hash) do
        {
          "adapter" => "mysql"
        }
      end

      it "does not raise error" do
        expect {
          Database.from(database_hash)
        }.not_to raise_error
      end

      it "deserialize correct" do
        database = Database.from(database_hash)
        expect(database.adapter).to eq("mysql")
      end

      it "raises error" do
        expect {
          Database.from(database_hash.merge("adapter" => 1))
        }.to raise_error(Exwiw::Serde::TypeError, "Type mismatch for Database#adapter. Expected String, got Integer.")
      end
    end

    context "optional case" do
      context "when attribute exists" do
        let(:table_hash) do
          {
            "name" => "users",
            "comment" => "This is a comment",
          }
        end

        it "does not raise error" do
          expect {
            Table.from(table_hash)
          }.not_to raise_error
        end

        it "deserialize correct" do
          table = Table.from(table_hash)
          expect(table.name).to eq("users")
          expect(table.comment).to eq("This is a comment")
        end

        it "raises error" do
          expect {
            Table.from(table_hash.merge("comment" => 1))
          }.to raise_error(Exwiw::Serde::TypeError, "Type mismatch for Table#comment. Expected optional(String), got Integer.")
        end
      end

      context "when attribute is missed" do
        let(:table_hash) do
          {
            "name" => "users",
          }
        end

        it "deserialize correct" do
          expect {
            Table.from(table_hash)
          }.not_to raise_error
        end

        it "does not raise error" do
          table = Table.from(table_hash)
          expect(table.name).to eq("users")
          expect(table.comment).to be_nil
        end
      end
    end

    context "array case" do
      let(:config_hash) do
        {
          "table_names" => ["users", "posts"]
        }
      end

      it "does not raise error" do
        expect {
          Config.from(config_hash)
        }.not_to raise_error
      end

      it "deserialize correct" do
        config = Config.from(config_hash)
        expect(config.table_names).to eq(["users", "posts"])
      end

      it "raises error" do
        expect {
          Config.from(config_hash.merge("table_names" => ["users", 1]))
        }.to raise_error(Exwiw::Serde::TypeError, "Type mismatch for Config#table_names. Expected array(String), got array(String, Integer)")
      end
    end
  end

  describe "serialize" do
    context "simple case" do
      let(:database) do
        Database.new.tap do |database|
          database.adapter = "mysql"
        end
      end

      it "serialize to hash correct" do
        expect(database.to_hash).to eq({ "adapter" => "mysql" })
      end
    end

    context "optional case" do
      context "when attribute exists" do
        let(:table) do
          Table.new.tap do |table|
            table.name = "users"
            table.comment = "This is a comment"
          end
        end

        it "serialize to hash correct" do
          expect(table.to_hash).to eq({
            "name" => "users",
            "comment" => "This is a comment",
          })
        end
      end

      context "when attribute is missed" do
        let(:table) do
          Table.new.tap do |table|
            table.name = "users"
          end
        end

        it "serialize to hash correct" do
          expect(table.to_hash).to eq({
            "name" => "users",
            "comment" => nil,
          })
        end
      end
    end

    context "array case" do
      let(:config) do
        Config.new.tap do |config|
          config.table_names = ["users", "posts"]
        end
      end

      it "serialize to hash correct" do
        expect(config.to_hash).to eq({
          "table_names" => ["users", "posts"],
        })
      end
    end
  end
end
