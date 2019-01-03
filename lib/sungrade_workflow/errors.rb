module SungradeWorkflow
  class BaseError < StandardError; end
  class MissingProcessDefinition < BaseError; end
  class ProcessNotRegistered < BaseError; end
  class ConfigurationError < BaseError; end
  class NoAvailableWaitingEvents < BaseError; end
  class UnableToRollback < BaseError; end
end
