require 'active_record'
require "iron_hide/version"
require 'iron_hide/errors'
require 'iron_hide/rule'
require 'iron_hide/condition'
require 'iron_hide/storage'
require 'iron_hide/configuration'

module IronHide
  class << self

    # @raise [IronHide::AuthorizationError] if authorization fails
    # @return [true] if authorization succeeds
    #
    def authorize!(user, action, resource)
      @_iron_hide_policy_authorized = true
      unless can?(user, action, resource)
        raise AuthorizationError
      end
      true
    end

    # @return [Boolean]
    # @param user [Object]
    # @param action [Symbol, String]
    # @param resource [Object]
    # @see IronHide::Rule::allow?
    #
    def can?(user, action, resource)
      IronHide::Rule.allow?(user, action.to_s, resource)
    end

    # @return [ActiveRecord::Relation]
    # @param user [Object]
    # @param resource [Object]
    # def scope(user, resource)
    #   IronHide::Rule.scope(user, "index", resource)
    # end
    # @return [IronHide::Storage]
    def storage
      @storage ||= IronHide::Storage.new(configuration.adapter)
    end

    attr_reader :configuration

    # @yield [IronHide::Configuration]
    def config
      yield configuration
    end

    def configuration
      @configuration ||= IronHide::Configuration.new
    end

    alias_method :configure, :config

    # Resets storage
    # Useful primarily for testing
    #
    # @return [void]
    def reset
      @storage = nil
    end

    def iron_hide_policy_authorized?
      !!@_iron_hide_policy_authorized
    end

    def verify_authorized
      raise AuthorizationNotPerformedError, self.class unless iron_hide_policy_authorized?
    end

    def skip_authorization
      @_iron_hide_policy_authorized = true
    end
  end
end

