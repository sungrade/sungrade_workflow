require_relative "process_attribute"

module SungradeWorkflow
  module Entity
    class ProcessCache
      attr_reader :klass

      def initialize(klass)
        @klass = klass
      end

      def process(name, **opts)
        process_cache[name] = ProcessAttribute.new(opts)
      end

      def process_cache
        @process_cache ||= {}
      end

      def process_attribute_for(name)
        process_cache.fetch(name) { raise ProcessNotRegistered.new("process #{name} not registered for #{klass}") }
      end
    end
  end
end
