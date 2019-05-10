require "sungrade_workflow/task/builder"

module SungradeWorkflow
  class Procedure
    class Builder
      attr_reader :process, :parent, :position, :blk, :participant

      def initialize(process:, parent:, position:, blk:, participant: nil, **opts)
        @process = process
        @parent = parent
        @position = position
        @participant = participant
        @blk = blk
      end

      def model_instance
        @model_instance ||= Storage.instance.create_procedure(
          process: process,
          parent: parent,
          position: position,
          participant_class: participant,
          blk: blk,
        )
      end

      def evaluate(blk)
        instance_eval(&blk)
      end

      def store!
        evaluate(blk)
        model_instance
        procedure_builders.each(&:store!)
        concurrence_builders.each(&:store!)
        task_builders.each(&:store!)
        wait_for_event_builders.each(&:store!)
        rollback_process_builders.each(&:store!)
      end

      private

      def procedure_builders
        @procedure_builders ||= []
      end

      def concurrence_builders
        @concurrence_builders ||= []
      end

      def task_builders
        @task_builders ||= []
      end

      def wait_for_event_builders
        @wait_for_event_builders ||= []
      end

      def rollback_process_builders
        @rollback_process_builders ||= []
      end

      def procedure(**opts, &blk)
        instance = self.class.new(
          process: process,
          parent: model_instance,
          position: queue.length,
          blk: blk,
          **opts
        )
        procedure_builders << instance
        queue << instance
      end

      def concurrence(**opts, &blk)
        instance = Concurrence::Builder.new(
          process: process,
          parent: model_instance,
          position: queue.length,
          blk: blk,
          **opts
        )
        concurrence_builders << instance
        queue << instance
      end

      def task(name, **opts)
        instance = Task::Builder.new(
          process: process,
          procedure: model_instance,
          position: queue.length,
          name: name,
          **opts
        )
        wait_for_event_builders << instance
        queue << instance
      end

      def wait_for_event(name, **opts)
        instance = WaitForEvent::Builder.new(
          process: process,
          procedure: model_instance,
          position: queue.length,
          name: name,
          **opts
        )
        rollback_process_builders << instance
        queue << instance
      end

      def rollback_process(name = nil, to:, **opts)
        instance = RollbackProcess::Builder.new(
          process: process,
          procedure: model_instance,
          position: queue.length,
          name: name,
          to: to,
          **opts
        )
        rollback_process_builders << instance
        queue << instance
      end

      def queue
        @queue ||= []
      end
    end
  end
end
