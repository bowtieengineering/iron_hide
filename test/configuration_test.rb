require 'test_helper'

describe IronHide::Configuration do
  describe "defaults" do
    it "initializes with default configuration variables" do
      configuration = IronHide::Configuration.new

      assert_equal configuration.adapter, :file
      assert_equal configuration.namespace, 'com::IronHide'
      assert_equal configuration.json, nil
    end
  end

  describe "::add_configuration" do
    it "creates an accessor and default values for additional configuration variables" do
      configuration = IronHide::Configuration.new

      configuration.add_configuration(var1: :default1, var2: :default2, var3: nil)

      assert_equal configuration.var1, :default1
      assert_equal configuration.var2, :default2

      configuration.var3 = :nondefault
      assert_equal configuration.var3, :nondefault
    end
  end
end
