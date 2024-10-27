# frozen_string_literal: true

RSpec.describe ZatsuLsp do
  describe "#add_workspace" do
    it "adds a workspace" do
      ZatsuLsp.add_workspace("sample/")
    end
  end
end
