module SungradeWorkflow
  class Participant
    class AbstractRollbackProcessParticipant < SungradeWorkflow::Participant::AbstractParticipant
      def auto_complete?
        true
      end
    end
  end
end
