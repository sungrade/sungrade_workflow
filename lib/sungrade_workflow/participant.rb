module SungradeWorkflow
  class Participant
    attr_reader :entity, :process

    def initialize(entity:, process:, storage_model:)
      @entity = entity
      @process = process
      @storage_model = storage_model
    end

    def auto_complete?
      if @storage_model.respond_to?(:should_autocomplete?)
        @storage_model.should_autocomplete?
      else
        false
      end
    end

    def up(**)
    end

    def down(**)
    end

    def before_skip(**); end
    def after_skip(**); end
    def before_available(**); end
    def after_available(**); end
    def before_dispatch(**); end
    def after_dispatch(**); end
    def before_complete(**); end
    def after_complete(**); end
    def before_rollback(**); end
    def after_rollback(**); end
  end
end

require "sungrade_workflow/participant/abstract_participant"
