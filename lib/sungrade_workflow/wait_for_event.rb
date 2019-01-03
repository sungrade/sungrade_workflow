require_relative "wait_for_event/builder"

module SungradeWorkflow
  class WaitForEvent
    attr_reader :storage_model

    def initialize(storage_model)
      @storage_model = storage_model
    end

    def complete(**args)
      storage_model.complete!(**args)
    end

    def auto_complete?
      participant.auto_complete?
    end

    def participant
      @participant ||= begin
        if storage_model.participant_class
          Module.const_get(storage_model.participant_class).new(
            entity: storage_model.entity,
            process: storage_model.root_process,
            storage_model: storage_model
          )
        else
          Participant::AbstractWaitForEventParticipant.new(
            entity: storage_model.entity,
            process: storage_model.root_process,
            storage_model: storage_model
          )
        end
      end
    end
  end
end

