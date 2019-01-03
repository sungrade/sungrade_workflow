module SungradeWorkflow
  class Process
    class Builder
      attr_reader :entity, :blk, :name, :version, :participant

      def initialize(entity:, blk:, name:, version:, participant: nil)
        @entity = entity
        @blk = blk
        @name = name
        @version = version
        @participant = participant
      end

      def build
        Storage.instance.current_storage.transaction do
          evaluate(blk)
          model_instance
          store!
        end
        process = entity.__process_for(model_instance.identifier)
        process.start!
        process
      end

      def model_instance
        @model_instance ||= Storage.instance.create_process(
          entity: entity,
          blk: blk,
          name: name,
          version: version,
          participant_class: participant
        )
      end

      def evaluate(blk)
        instance_eval(&blk)
      end

      def store!
        procedure_builders.each(&:store!)
        concurrence_builders.each(&:store!)
      end

      private

      def procedure(**opts, &blk)
        instance = Procedure::Builder.new(
          process: model_instance,
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
          process: model_instance,
          parent: model_instance,
          position: queue.length,
          blk: blk,
          **opts
        )
        concurrence_builders << instance
        queue << instance
      end

      def procedure_builders
        @procedure_builders ||= []
      end

      def concurrence_builders
        @concurrence_builders ||= []
      end

      def queue
        @queue ||= []
      end
    end
  end
end

require "sungrade_workflow/procedure/builder"
require "sungrade_workflow/concurrence/builder"
