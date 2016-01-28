require 'test_helper'

class TestScope < Minitest::Test
  def setup
    IronHide.config do |c|
      c.adapter = :file
      c.json = 'test/rules.json'
      c.memoize = false
      c.namespace = "com::test"
    end
    @user = User.new("123")
    @rules = IronHide::Rule.find(@user,"index",Resource)
  end
  def teardown
    IronHide.reset
  end
  def test_that_scope_is_a_scope
    assert_instance_of IronHide::ScopeBuilder, IronHide::ScopeBuilder.new(@user,Resource,@rules), "It should be an instance of IronHide::ScopeBuilder"
  end

  def test_find_one_rule
    assert_equal 2, @rules.length
  end
end
