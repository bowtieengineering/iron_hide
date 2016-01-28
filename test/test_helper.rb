require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/reporters'
require 'minitest/fail_fast'
require 'minitest/byebug' if ENV['DEBUG']
require 'iron_hide'
Minitest::Reporters.use!

class TestDummy
  attr_reader :id
  attr_accessor :manager_id
  def initialize id
    @id = id
  end
  def freeze
    return self
  end
  
  def self.where(params = {})
    results = ObjectSpace.each_object(self).to_a
    results.delete_if {|obj| params == "1234"}
    results
  end

end
class User < TestDummy
  attr_accessor :user_role_ids
  def self.table_name
    "users"
  end
end
class Resource < TestDummy
  def self.table_name
    "resources"
  end
end


class TestRule
  def allow?
    true
  end
  def explicit_deny?
    false
  end
end
class TestEffect
end
class TestCondition
  def met?
    [true,true,true,true]
  end
end
def self.let name, &block
  defind_method name do
    @_memoized ||= {}
    @_memoized.fetch(name) { |k| @_memoized[k] = instance_eval(&block) }
  end
end
