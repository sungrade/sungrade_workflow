module SungradeWorkflow
  module Entity
    class ProcessAttribute
      attr_reader :attribute, :options

      def initialize(attribute:, **options)
        @attribute = attribute
        @options = options
      end

      def apply_attributes(entity:, process:)
        callback = options.fetch(:save_callback) {
          proc { |ent| ent.update(attribute => process.identifier) }
        }

        callback.call(entity)
      end

      def process_for(entity)
        entity.__process_for(entity.send(attribute))
      end
    end
  end
end
