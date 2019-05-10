module SungradeWorkflow
  class RollbackProcess
    attr_reader :storage_model

    def initialize(storage_model)
      @storage_model = storage_model
    end

    def complete(**args)
      storage_model.complete!(**args)
    end

    def rollback(**args)
      storage_model.rollback!(**args)
    end

    def auto_complete?
      participant.auto_complete?
    end

    def to
      storage_model.to
    end

    def process
      storage_model.root_process.wrapper
    end

    def participant
      @participant ||= begin
        if storage_model.participant_class
          Module.const_get(storage_model.participant_class).new(
            entity: storage_model.entity,
            process: process,
            storage_model: storage_model
          )
        else
          Participant::AbstractRollbackProcessParticipant.new(
            entity: storage_model.entity,
            process: process,
            storage_model: storage_model
          )
        end
      end
    end
  end
end

require_relative "rollback_process/builder"