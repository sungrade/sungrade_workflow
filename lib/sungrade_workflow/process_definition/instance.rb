require "sungrade_workflow/process"

module SungradeWorkflow
  module ProcessDefinition
    class Instance
      attr_reader :name, :version, :blk, :participant

      def initialize(name:, version:, blk:, participant:)
        @name = name
        @version = version
        @blk = blk
        @participant = participant
      end

      def build(entity:)
        Process::Builder.new(
          entity: entity,
          blk: blk,
          name: name,
          version: version,
          participant: participant
        ).build
      end
    end
  end
end
