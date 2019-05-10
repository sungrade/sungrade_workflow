module SungradeWorkflow
  class Procedure
    attr_reader :storage_model

    def initialize(storage_model)
      @storage_model = storage_model
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
            storage_model: self
          )
        else
          Participant::AbstractProcedureParticipant.new(
            entity: storage_model.entity,
            process: process,
            storage_model: self
          )
        end
      end
    end
  end
end

require_relative "procedure/builder"
