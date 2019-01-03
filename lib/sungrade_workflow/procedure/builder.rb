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
        task_builders << instance
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
        task_builders << instance
        queue << instance
      end

      def queue
        @queue ||= []
      end
    end
  end
end
