require "sungrade_workflow/version"
require "sungrade_workflow/errors"
require "sungrade_workflow/storage"
require "sungrade_workflow/configuration"
require "sungrade_workflow/process_definition/all"
require "sungrade_workflow/entity"
require "sungrade_workflow/participant"
require "sungrade_workflow/concurrence"
require "sungrade_workflow/procedure"
require "sungrade_workflow/wait_for_event"
require "sungrade_workflow/rollback_process"
require "sungrade_workflow/process"
require "sungrade_workflow/task"
require "sungrade_workflow/claimant"
require "sungrade_workflow/middleware"
require "sungrade_workflow/railtie" if defined?(Rails::Railtie)

module SungradeWorkflow
  class << self
    def register_process(name:, version:, collection: ProcessDefinition::Collection.instance, participant: nil, &blk)
      collection.add(name: name, version: version, blk: blk, participant: participant)
    end

    def bootstrap!
      Configuration.validate!
      Configuration.begin!
      Storage.bootstrap!
      ProcessDefinition::Collection.instance.begin!
      begin!
    end

    def clear!
      @has_begun = false
      # ProcessDefinition::Collection.instance.clear!
    end

    def begin!
      return if @has_begun
      @has_begun = true
      # ProcessDefinition::Collection.instance.begin!
      # Configuration.begin!
    end

    def configure(&blk)
      Configuration.evaluate(blk)
    end

    def config
      Configuration.instance
    end
  end
end
