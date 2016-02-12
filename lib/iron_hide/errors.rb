module IronHide
  # All exceptions inherit from IronHideError to allow rescuing from all
  # exceptions that occur in this gem.
  #
  class IronHideError < StandardError      ; end

  # Exception raised when an authorization failure occurs.
  # Typically when IronHide::authorize! is invoked
  #
  class AuthorizationError < IronHideError ; end

  # Exception raised when a conditional is incorrectly defined
  # in the rules.
  # @see IronHide::Condition
  #
  class InvalidConditional < IronHideError ; end

  # Exception raised when authorization is not performed, usually used
  # as an 'after_action' filter to prevent programmer error in forgetting
  # to call {#authorize!} or {#skip_authorization}
  class AuthorizationNotPerformedError < IronHideError ; end
end
