module SungradeWorkflow
  class RollbackProcess
    class Builder
      attr_reader :process, :procedure, :position, :to, :name, :participant

      def initialize(process:, procedure:, position:, to:, name:, participant: nil, **opts)
        @process = process
        @procedure = procedure
        @position = position
        @to = to
        @participant = participant
      end

      def model_instance
        @model_instance ||= Storage.instance.create_rollback_process(
          process: process,
          procedure: procedure,
          position: position,
          to: to,
          name: name,
          participant_class: participant,
        )
      end

      def store!
        model_instance
      end
    end
  end
end
