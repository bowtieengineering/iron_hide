require 'test_helper'

describe IronHide do
  let(:user)     { User.new("123") }
  let(:action)   { 'read' }
  let(:resource) { Resource.new("123") }

  describe "::authorize!" do
    describe "when the rules allow" do
      it "returns true" do
        IronHide::Rule.stub(:allow?, true) do
          assert IronHide.authorize!(user, action, resource)
        end
      end
    end

    describe "when the rules do not allow" do

      it "raise IronHide::AuthorizationError" do
        IronHide::Rule.stub(:allow?, false) do
          assert_raises(IronHide::AuthorizationError) {IronHide.authorize!(user, action, resource) }
        end
      end
    end
  end

  describe "::can?" do
    describe "when the rules allow" do

      it "returns true" do
        IronHide::Rule.stub(:allow?, true) do
          assert IronHide.can?(user, action, resource)
        end
      end
    end
    describe "when the rules do not allow" do

      it "returns false" do
        IronHide::Rule.stub(:allow?, false) do
          refute IronHide.can?(user, action, resource)
        end
      end
    end
  end

  describe "::storage" do
    def setup
      IronHide.configure do |config|
        config.adapter = :file
        config.json    = 'test/rules.json'
      end
    end

    def teardown
      IronHide.reset
    end

    it "returns an IronHide::Storage object" do
      assert_instance_of IronHide::Storage, IronHide.storage
    end
  end

  def setup
    IronHide.configure do |config|
      config.adapter = :file
      config.json    = 'test/rules.json'
    end
  end
  def teardown
    IronHide.reset
  end

  def test_scope_returns_scoped_resources
    @resource = Resource.new("643243")
    @resource2 = Resource.new("1234")
    #assert_instance_of ActiveRecord::Relation, IronHide.scope(user,resource)
    assert_includes IronHide.scope(user,Resource), @resource
    refute_includes IronHide.scope(user,Resource), @resource2

  end
end
