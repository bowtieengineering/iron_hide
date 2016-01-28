require 'test_helper'

describe IronHide::Storage do
  describe "ADAPTERS" do
    it "returns a Hash of valid adapter types" do
      assert_equal IronHide::Storage::ADAPTERS, {
          file: :FileAdapter
        }
    end
  end
end
