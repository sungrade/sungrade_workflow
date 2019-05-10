require_relative "instance"

module SungradeWorkflow
  module ProcessDefinition
    class Collection
      class << self
        def instance
          @instance ||= new
        end
      end

      def clear!
        @collection = {}
      end

      def begin!

      end

      def add(name:, version:, blk:, participant:)
        if collection.key?(name)
          raise "Duplicate process definition for #{name}"
        else
          collection[name] = Instance.new(name: name, version: version, blk: blk, participant: participant)
        end
      end

      def process_definition_for(name)
        collection.fetch(name) { raise MissingProcessDefinition.new("No process with the name: #{name}") }
      end

      def collection
        @collection ||= {}
      end
    end
  end
end
