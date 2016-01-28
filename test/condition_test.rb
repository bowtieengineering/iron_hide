require 'test_helper'

describe IronHide::Condition do
  describe "VALID_TYPES" do
    it "returns a Hash that maps condition types to class names" do
      IronHide::Condition::VALID_TYPES.must_equal({ 
        'equal' => :EqualCondition, 
        'not_equal' => :NotEqualCondition 
      })
    end

    it "returns a frozen object" do
      assert IronHide::Condition::VALID_TYPES.frozen?
    end
  end

  # The manager_id of the resource must equal the user's manager_id
  # The user's user_role_ids must include 1, 2, 3, or 4 (logical OR)
  let(:eq_params) do
    {
      'equal'=> {
        'resource::manager_id' => ['user::manager_id'] ,
        'user::user_role_ids' => [1,2,3,4]
      }
    }
  end

  # The manager_id of the resource must not equal the user's manager_id
  let(:not_eq_params) do
    {
      'not_equal'=> { 'resource::manager_id' => ['user::manager_id'] },
    }
  end

  let(:eq_condition) { IronHide::Condition.new(eq_params) }
  let(:not_eq_condition) { IronHide::Condition.new(not_eq_params) }
  let(:user) { User.new("1234") }
  let(:resource) { Resource.new("2345") }

  # See: https://github.com/rspec/rspec-mocks/issues/494
  # These objects are frozen to protect them from modification.
  # RSpec modifies the meta-class of the objects when setting method exepctations,
  # so we need to stub #freeze and render it useless.
  #
  # before do
  #   user.stub(:freeze, user)
  #   resource.stub(:freeze, resource)
  # end

  describe "::new" do
    describe "when condition type is 'equal'" do
      it "returns an instance of EqualCondition" do
        assert_instance_of IronHide::EqualCondition, eq_condition
      end
    end

    describe "when condition type is 'not_equal'" do
      it "returns an instance of NotEqualCondition" do
        assert_instance_of IronHide::NotEqualCondition, not_eq_condition
      end
    end

    describe "when more than 1 key present in params" do
      let(:invalid_params) { not_eq_params.merge(eq_params) }

      it "raises IronHide::InvalidConditional exception" do
        assert_raises(IronHide::InvalidConditional) { IronHide::Condition.new(invalid_params) }
      end
    end

    describe "when condition type is unknown" do
      let(:invalid_params) { { 'wrong' => { 'resource::manager_id' => ['user::manager_id']} } }

      it "raises an error" do
        assert_raises(IronHide::InvalidConditional) { IronHide::Condition.new(invalid_params) }
      end
    end
  end

  describe "#met?" do
    describe "when condition type is 'equal'" do
      describe "when all expressions in the condition are met (logical AND)" do

        let(:role_ids)  { [1,2] }
        let(:manager_id) { 99 }

        it "returns true" do
          user.stub(:user_role_ids, role_ids) do
            user.stub(:manager_id, manager_id) do
              resource.stub(:manager_id, manager_id) do
                assert eq_condition.met?(user, resource)
              end
            end
          end
        end
      end

      describe "when all expressions in the condition are not met" do

        let(:role_ids)  { [] }
        let(:manager_id) { 99 }

        it "returns false" do
          user.stub(:user_role_ids, role_ids) do
            user.stub(:manager_id, manager_id) do
              resource.stub(:manager_id, manager_id) do
                refute eq_condition.met?(user, resource)
              end
            end
          end
        end
      end

      describe "when conditional expressions are empty" do
        before { eq_params['equal'] = {} }
        it "returns true" do
          assert eq_condition.met?(user,resource)
        end
      end
    end

    describe "when condition type is :not_equal" do
      describe "when all expressions in the condition are met (logical AND)" do

        let(:manager_id) { 99 }

        it "returns true" do
          user.stub(:manager_id, manager_id) do
            # Satisfy the condition that manager_id of the resource and user don't match
            resource.stub(:manager_id, manager_id + 1) do
              assert not_eq_condition.met?(user,resource)
            end
          end
        end
      end

      describe "when all expressions in the condition are not met" do
        # Don't satisfy the condition by setting the manager_ids on user
        # and resource to be the same
        let(:manager_id) { 99 }

        it "returns false" do
          user.stub(:manager_id, manager_id) do
            resource.stub(:manager_id, manager_id) do
              refute not_eq_condition.met?(user,resource)
            end
          end
        end
      end

      describe "when conditional expressions are empty" do
        before { not_eq_params['not_equal'] = {} }
        it "returns true" do
          assert not_eq_condition.met?(user,resource)
        end
      end
    end

    describe "when conditional expressions are invalid" do
      describe "when key is invalid" do
        # The key can only reference a 'user' or 'resource', otherwise,
        # it's an invalid expression
        let(:eq_params) do
          {
            'equal' => {
              'something_wrong::manager_id' => ['user::manager_id'] ,
              'user::user_role_ids' => [1,2,3,4]
            }
          }
        end

        it "raises an InvalidConditional error" do
          assert_raises (IronHide::InvalidConditional) { eq_condition.met?(user, resource)}
        end
      end

      describe "when value is nil" do

        let(:eq_params) do
          {
            'equal' => nil
          }
        end

        it "raises an InvalidConditional error" do
          user.stub(:manager_id, 1) do
            assert_raises (IronHide::InvalidConditional) { eq_condition.met?(user, resource)}
          end
        end
      end

      describe "when value is wrong type" do

        let(:eq_params) do
          {
            'equal' => "wrong_type"
          }
        end

        it "raises an InvalidConditional error" do
          user.stub(:manager_id, 1) do
            assert_raises (IronHide::InvalidConditional) { eq_condition.met?(user, resource)}
          end
        end
      end
    end

    #TODO: Additional tests.
    # duplication of the same information that conflicts / conditions that cannot be satisfied
  end

  describe "#evaluate" do
    let(:condition) { IronHide::Condition.new(eq_params) }

    describe "when input is a valid expression" do
      let(:input1) { 'user::manager_id' }
      let(:input2) { 'resource::manager_id' }
      let(:input3) { 'user' }
      let(:input4) { 'resource' }

      it "returns the evaluated expression" do
        user.stub(:manager_id, 1) do
          resource.stub(:manager_id, 5) do
            assert_equal condition.send(:evaluate, input1, user, resource), [1]
            assert_equal condition.send(:evaluate, input2, user, resource), [5]
            assert_equal condition.send(:evaluate, input3, user, resource), [user]
            assert_equal condition.send(:evaluate, input4, user, resource), [resource]
          end
        end
      end
    end

    describe "when input is not a valid expression" do
      let(:input1) { 'user::instance_eval()' }
      let(:input2) { 'user::delete!' }
      let(:input3) { 'user::id=' }
      let(:input4) { 'user::' }
      let(:input5) { 'user::something::' }

      it "returns the input" do
        user.stub(:manager_id, 1) do
          resource.stub(:manager_id, 5) do
            assert_equal condition.send(:evaluate, input1, user, resource), [input1]
            assert_equal condition.send(:evaluate, input2, user, resource), [input2]
            assert_equal condition.send(:evaluate, input3, user, resource), [input3]
            assert_equal condition.send(:evaluate, input4, user, resource), [input4]
            assert_equal condition.send(:evaluate, input5, user, resource), [input5]
          end
        end
      end
    end
  end
end
