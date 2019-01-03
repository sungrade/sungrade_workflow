require_relative "concurrence/builder"

module SungradeWorkflow
  class Concurrence
    attr_reader :storage_model

    def initialize(storage_model)
      @storage_model = storage_model
    end

    def participant
      @participant ||= begin
        if storage_model.participant_class
          Module.const_get(storage_model.participant_class).new(
            entity: storage_model.entity,
            process: storage_model.root_process,
            storage_model: self
          )
        else
          Participant::AbstractConcurrenceParticipant.new(
            entity: storage_model.entity,
            process: storage_model.root_process,
            storage_model: self
          )
        end
      end
    end
  end
end
