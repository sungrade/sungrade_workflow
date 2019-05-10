module SungradeWorkflow
  class Process
    attr_reader :storage_model, :claimant

    def initialize(storage_model)
      @storage_model = storage_model
    end

    def identifier
      storage_model.identifier
    end

    def start!(claimant: nil, **opts)
      @claimant = claimant
      storage_model.start!(initial_start: true, claimant: claimant, **opts)
    end

    def cancel!(claimant: nil, **opts)
      @claimant = claimant
      storage_model.cancel!(claimant: claimant, **opts)
    end

    def task_for(name)
      task = storage_model.task_for(name)
      task&.wrapper
    end

    def available_tasks_for_claimant(claimant)
      require "pry"; binding.pry; 1
    end

    def available_tasks(*names)
      storage_model.available_tasks(*names).map(&:wrapper)
    end

    def completed_tasks(*names)
      storage_model.completed_tasks(*names).map(&:wrapper)
    end

    def waiting_events(*names)
      storage_model.waiting_events(*names).map(&:wrapper)
    end

    def trigger_event(name:, raise_error: true, **opts)
      events = waiting_events(name)
      if events.any? && raise_error
        raise NoAvailableWaitingEvents.new("Currently not waiting for #{name}")
      end
      events.each { |event| event.complete(**opts) }
    end

    def participant
      @participant ||= begin
        if storage_model.participant_class
          Module.const_get(storage_model.participant_class).new(
            entity: storage_model.entity,
            process: self,
            storage_model: storage_model
          )
        else
          Participant::AbstractProcessParticipant.new(
            entity: storage_model.entity,
            process: self,
            storage_model: storage_model
          )
        end
      end
    end
  end
end

require_relative "process/builder"
