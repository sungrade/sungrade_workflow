require "sungrade_workflow/process/builder"

module SungradeWorkflow
  class Concurrence
    class Builder
      attr_reader :process, :parent, :position, :blk, :count, :participant

      def initialize(process:, parent:, position:, blk:, count: nil, participant: nil, **opts)
        @process = process
        @parent = parent
        @position = position
        @count = count
        @participant = participant
        @blk = blk
      end

      def model_instance
        @model_instance ||= Storage.instance.create_concurrence(
          process: process,
          parent: parent,
          position: position,
          participant_class: participant,
          count: count,
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
      end

      private

      def procedure_builders
        @procedure_builders ||= []
      end

      def concurrence_builders
        @concurrence_builders ||= []
      end

      def procedure(**opts, &blk)
        instance = Procedure::Builder.new(
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
        instance = self.class.new(
          process: process,
          parent: model_instance,
          position: queue.length,
          blk: blk,
          **opts
        )
        concurrence_builders << instance
        queue << instance
      end

      def queue
        @queue ||= []
      end
    end
  end
end
