require 'test_helper'
require 'tempfile'

describe "Integration Testing" do
  def setup
    @file = Tempfile.new('rules')
    @file.write <<-RULES
      [
        {
          "resource": "com::test::TestResource",
          "action": ["read", "write"],
          "description": "Read/write access for TestResource.",
          "effect": "allow",
          "conditions": [
            {
              "equal": {
                "user::role_ids": [1],
                "user::name": ["Cyril Figgis"]
              }
            }
          ]
        },
        {
          "resource": "com::test::TestResource",
          "action": ["disable"],
          "description": "Read/write access for TestResource.",
          "effect": "deny",
          "conditions": [
            {
              "equal": {
                "user::role_ids": [99]
              }
            }
          ]
        },
        {
          "resource": "com::test::TestResource",
          "action": ["read"],
          "description": "Read access for TestResource.",
          "effect": "allow",
          "conditions": [
            {
              "equal": {
                "user::role_ids": [5]
              }
            }
          ]
        },
        {
          "resource": "com::test::TestResource",
          "action": ["read"],
          "effect": "deny",
          "conditions": [
            {
              "equal": {
                "resource::active": [false]
              }
            }
          ]
        },
        {
          "resource": "com::test::TestResource",
          "action": ["destroy"],
          "effect": "allow",
          "description": "Rule with multiple conditions",
          "conditions": [
            {
              "equal": {
                "resource::active": [false]
              }
            },
            {
              "not_equal": {
                "user::role_ids": [954]
              }
            }
          ]
        },
        {
          "resource": "com::test::TestResource",
          "action": ["fire"],
          "effect": "allow",
          "description": "Rule with nested attributes",
          "conditions": [
            {
              "equal": {
                "user::manager::name": ["Lumbergh"]
              }
            }
          ]
        }
      ]
    RULES
    @file.rewind
    IronHide.configure do |config|
      config.adapter   = :file
      config.json      = @file.path
      config.namespace = "com::test"
    end
  end

  def teardown
    IronHide.reset
    @file.close
  end

  class TestUser
    attr_accessor :role_ids, :name
    def initialize
      @role_ids = []
    end

    def manager
      @manager ||= TestUser.new
    end
  end

  class TestResource
    attr_accessor :active
  end

  let(:user)     { TestUser.new }
  let(:resource) { TestResource.new }

  describe "when one rule matches an action" do
    describe "when effect is 'allow'" do
      let(:action) { 'write' }
      let(:rules)  { IronHide::Rule.find(user,action,resource) }
      specify      { assert_equal rules.size, 1 }
      specify      { assert_equal rules.first.effect, 'allow' }

      describe "when all conditions are met" do
        before do
          user.role_ids << 1 << 2
          user.name = 'Cyril Figgis'
        end

        specify { assert IronHide.can?(user,action,resource) }
        specify { assert IronHide.authorize!(user,action,resource), "#{IronHide::Rule.find(user,action,resource)}" }
      end

      describe "when some conditions are met" do
        before do
          user.role_ids << 1 << 2
          user.name = 'Pam'
        end

        specify { refute IronHide.can?(user,action,resource) }
        specify { assert_raises(IronHide::AuthorizationError) { IronHide.authorize!(user,action,resource) } }
      end
    end

    describe "when effect is 'deny'" do
      let(:action) { 'disable' }
      let(:rules)  { IronHide::Rule.find(user,action,resource) }
      specify      { assert_equal rules.size, 1, "#{IronHide::Rule.find(user,action,resource)}" }
      specify      { assert_equal rules.first.effect, 'deny' }

      describe "when all conditions are met" do
        before { user.role_ids << 99 }
        specify { refute IronHide.can?(user,action,resource) }
        specify { assert_raises(IronHide::AuthorizationError) { IronHide.authorize!(user,action,resource) } }
      end

      describe "when no conditions are met" do
        specify { refute IronHide.can?(user,action,resource) }
        specify { assert_raises (IronHide::AuthorizationError) {IronHide.authorize!(user,action,resource) } }
      end
    end
  end

  describe "when no rule matches an action" do
    let(:action) { 'some-crazy-rule' }
    let(:rules)  { IronHide::Rule.find(user,action,resource) }
    specify      { assert_equal rules.size, 0 }
    specify { refute IronHide.can?(user,action,resource) }
    specify {assert_raises (IronHide::AuthorizationError) {IronHide.authorize!(user,action,resource) } }
  end

  describe "when multiple rules match an action" do
    let(:action) { 'read' }
    let(:rules)  { IronHide::Rule.find(user,action,resource) }
    specify      { assert_equal 3, rules.size }

    describe "when conditions for only one rule are met" do
      describe "when effect is 'allow'" do
        before  { user.role_ids << 5 }
        specify { assert IronHide.can?(user,action,resource) }
        specify { assert IronHide.authorize!(user,action,resource) }
      end

      describe "when effect is 'deny'" do
        before { resource.active = false }
        specify { refute IronHide.can?(user,action,resource) }
        specify { assert_raises(IronHide::AuthorizationError) { IronHide.authorize!(user,action,resource) } }
      end
    end

    describe "when conditions for all rules are met" do
      describe "when at least one rule's effect is 'deny'" do
        before  do
          resource.active = false
          user.name = 'Cyril Figgis'
          user.role_ids << 5
        end

        specify { refute IronHide.can?(user,action,resource) }
        specify { assert_raises(IronHide::AuthorizationError) {IronHide.authorize!(user,action,resource) } }
      end
    end
  end

  describe "testing rule with multiple conditions" do
    let(:action) { 'destroy' }
    let(:rules)  { IronHide::Rule.find(user,action,resource) }
    specify      { assert_equal rules.size, 1, "#{IronHide.storage.adapter.rules}" }
    describe "when only one condition is met" do
      before  { resource.active = false ; user.role_ids << 954 }
      specify { refute IronHide.can?(user,action,resource) }
      specify { assert_raises(IronHide::AuthorizationError) { IronHide.authorize!(user,action,resource) } }
    end

    describe "when all conditions are met" do
      before  { resource.active = false ; user.role_ids << 25 }
      specify { assert IronHide.can?(user,action,resource) }
      specify { assert IronHide.authorize!(user,action,resource) }
    end
  end

  describe "testing rule with nested attributes" do
    let(:action) { 'fire' }
    let(:rules)  { IronHide::Rule.find(user,action,resource) }
    describe "when conditions are met" do
      before  { user.manager.name = "Lumbergh" }
      specify { assert IronHide.can?(user,action,resource) }
      specify { assert IronHide.authorize!(user,action,resource), "#{user} | #{action} | #{resource}" }
    end
    describe "when conditions are not met" do
      before  { user.manager.name = "Phil" }
      specify { refute IronHide.can?(user,action,resource) }
      specify { assert_raises(IronHide::AuthorizationError) { IronHide.authorize!(user,action,resource) } }
    end
  end
end

