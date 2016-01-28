require 'test_helper'

describe IronHide::Rule do
  def teardown
    IronHide.reset
  end
  describe "ALLOW" do
    it "returns 'allow'" do
      assert_equal IronHide::Rule::ALLOW, 'allow'
    end
  end

  describe "DENY" do
    it "returns 'deny'" do
      assert_equal IronHide::Rule::DENY, 'deny'
    end
  end

  describe "::find" do
    def setup
      IronHide.configure do |config|
        config.adapter = :file
        config.json    = 'test/rules.json'
        config.namespace = "com::test"
      end
    end

    let(:action)   { 'read' }
    let(:resource) { Resource.new("1234") }
    let(:user)     { User.new("123") }

    it "returns a collection of Rule instances that match an action and resource" do
      skip
      assert_instance_of IronHide::Rule, IronHide::Rule.find(user,action,resource).first, "#{user} | #{action} | #{resource} | #{IronHide.storage.adapter.rules} | #{File.open("test/rules.json").read}"
    end
  end

  describe "::allow?" do
    let(:action)   { 'read' }
    let(:resource) { Resource.new("1234") }
    let(:user)     { User.new("123") }
    let(:rule1)    { TestRule.new }
    let(:rule2)    { TestRule.new }
    let(:rules)    { [ rule1, rule1, rule2 ] }

    describe "when all Rules allow the action" do
      it "returns true" do
        IronHide::Rule.stub(:find, rules) do
          assert IronHide::Rule.allow?(user,action,resource)
        end
      end
    end

    describe "when at least one Rule does not allow the action" do
      describe "when it does NOT explictly deny" do
        it "returns true" do
          rule2.stub(:allow?, false) do
            rule2.stub(:explicit_deny?, false) do
              IronHide::Rule.stub(:find, rules) do
                assert IronHide::Rule.allow?(user,action,resource)
              end
            end
          end
        end
      end

      describe "when it does explicitly deny" do
        it "returns false" do
          rule2.stub(:explicit_deny?, true) do
            IronHide::Rule.stub(:find, rules) do
              assert IronHide::Rule.allow?(user,action,resource)
            end
          end
        end
      end
    end

    describe "when no rules match" do
      it "returns false" do
        IronHide::Rule.stub(:find, []) do
          refute IronHide::Rule.allow?(user,action,resource)
        end
      end
    end
  end

  describe "::storage" do
    it "returns an IronHide::Storage instance" do
      assert_instance_of IronHide::Storage, IronHide::Rule.storage
    end
  end

  def setup
    @params = {
      'action'=> :test_action,
      'effect'=> effect,
      'conditions'=> [
        {
          "equal" => { 
            "user::id" => [1,2,3,4]
          }
        }
      ]
    }
  end

  let(:condition) { TestCondition.new }
  let(:user)      { User.new("123") }
  let(:resource)  { Resource.new("2345") }
  let(:effect)    { TestEffect.new }
  let(:rule)      { IronHide::Rule.new(user, resource, @params) }

  describe "#initialize" do
    it "assigns user, action, description, effect, and conditions" do
      IronHide::Condition.stub(:new, condition) do
        assert_equal rule.user, user
        assert_equal rule.resource, resource
        assert_equal rule.conditions, 1.times.map { condition }
      end
    end
  end

  describe "#allow?" do
    describe "when at least one condition is not met" do
      it "returns false" do
        IronHide::Condition.stub(:new, condition) do
          condition.stub(:met?,[true,true,true,false]) do
            refute rule.allow?
          end
        end
      end
    end

    describe "when all conditions are met" do
      describe "when effect is allow" do
        it "returns true" do
          condition.stub(:met?,true) do
            IronHide::Condition.stub(:new, condition) do
              @params["effect"] = IronHide::Rule::ALLOW
              assert rule.allow?, "#{rule.conditions.first.met?}"
            end
          end
        end
      end

      describe "when effect is deny" do
        it "returns false" do
          condition.stub(:met?,true) do
            IronHide::Condition.stub(:new, condition) do
              @params["effect"] = IronHide::Rule::DENY
              refute rule.allow?
            end
          end
        end
      end
    end

    describe "when all conditions are not met" do
      it "returns false" do
        condition.stub(:met?,false) do
          IronHide::Condition.stub(:new, condition) do
            @params["effect"] = IronHide::Rule::ALLOW
            refute rule.allow?
          end
        end
      end
    end

    describe "when there are no conditions" do
      def setup
        @params = {
          'action'=> :test_action,
          'effect'=> effect,
          'conditions'=> []
        }
      end

      describe "when effect is ALLOW" do
        let(:effect) { IronHide::Rule::ALLOW }

        it "returns true" do
          assert rule.allow?
        end
      end

      describe "when effect is DENY" do
        let(:effect) { IronHide::Rule::DENY }

        it "returns false" do
          refute rule.allow?
        end
      end
    end
  end

  describe "#explicit_deny?" do
    describe "when at least one condition is not met" do
      it "returns false" do
        IronHide::Condition.stub(:new, condition) do
          condition.stub(:met?,[true,true,true,false]) do
            refute rule.explicit_deny?
          end
        end
      end
    end

    describe "when all conditions are met" do
      describe "when effect is DENY" do
        let(:effect) { IronHide::Rule::DENY }

        it "returns true" do
          IronHide::Condition.stub(:new, condition) do
            condition.stub(:met?,true) do
              assert rule.explicit_deny?
            end
          end
        end
      end

      describe "when effect is ALLOW" do
        let(:effect) { IronHide::Rule::ALLOW }

        it "returns false" do
          IronHide::Condition.stub(:new, condition) do
            refute rule.explicit_deny?
          end
        end
      end
    end

    describe "when all conditions are not met" do
      it "returns false" do
        condition.stub(:met?,false) do
          refute rule.explicit_deny?
        end
      end
    end

    describe "when there are no conditions" do
      def setup
        @params = {
          'action'=> :test_action,
          'effect'=> effect,
          'conditions'=> []
        }
      end

      describe "when effect is ALLOW" do
        let(:effect) { IronHide::Rule::ALLOW }

        it "returns false" do
          refute rule.explicit_deny?
        end
      end

      describe "when effect is DENY" do
        let(:effect) { IronHide::Rule::DENY }

        it "returns true" do
          assert rule.explicit_deny?
        end
      end
    end
  end
end
