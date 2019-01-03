module SungradeWorkflow
  class Participant
    class AbstractParticipant < SungradeWorkflow::Participant

    end
  end
end

require_relative "abstract_task_participant"
require_relative "abstract_concurrence_participant"
require_relative "abstract_procedure_participant"
require_relative "abstract_process_participant"
require_relative "abstract_wait_for_event_participant"
