module IronHide
  class ScopeBuilder
    # return [IronHide::Scope]
    # @param conditions [Array<IronHide::Condition>]
    # @param user [Object]
    # @param resource [Object]
    def self.build_scope(conditions, user, resource)
      evaluation = conditions.reduce([]) do |c,val|
        c << val.scope(user,resource)
      end
      new(user,resource,evaluation.flatten(1))
    end

    # return [IronHide::Scope]
    # @param user [Object]
    # @param resource [Object]
    # @param scope [Arel::SelectManager]
    def initialize(user,resource,rules)
      @user = user
      @resource = resource
      @scope = self.create_scope(rules)
    end

    attr_reader :user, :resource, :scope

    def self.build(user,resource,scope)
      new(user,resource,scope)
    end

    def create_scope(rules)
      rules.reduce([]) do |query,rule|
        results = rule.conditions.reduce([]) do |info,condition|
          info << condition.scope(user,resource).flatten
          info
        end
        query << [rule.effect,results]
      end
      # first_reduction = scope.reduce([]) do |ary,item|
      #   action = item.first
      #   attribute = item.second.first
      #   value = item.third
      #   if attribute.is_a? Arel::Attributes::Attribute
      #     if action == 'equal'
      #       ary << attribute.eq_any(value)
      #     else
      #       ary << attribute.not_eq_any(value)
      #     end
      #   elsif attribute.is_a? String
      #     if action == 'equal'
      #       unless value.include? attribute
      #         break
      #       end
      #     else
      #       if value.include? attribute
      #         break
      #       end
      #     end
      #   else
      #   end
      #   ary
      # end
      # first_reduction.inject(Arel::Table.new(resource.name.split("::").join("").underscore.to_sym))
    end
  end
end
