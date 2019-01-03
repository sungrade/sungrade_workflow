require_relative "entity/process_cache"

module SungradeWorkflow
  module Entity
    def self.included(klass)
      klass.extend(ClassMethods)
      klass.include(InstanceMethods)
    end

    module ClassMethods
      def process(name, attribute:, method_name:, **opts)
        instance = process_cache.process(name, attribute: attribute, method_name: method_name, **opts)
        self.class_eval do
          define_method(method_name) do
            var = "@_sungrade_workflow_#{method_name}_process"
            if ret = instance_variable_get(var)
              ret
            else
              process = instance.process_for(self)
              instance_variable_set(var, process)
            end
          end
        end
      end

      def process_cache
        @process_cache ||= ProcessCache.new(self)
      end

      def identifier_method(meth)
        @identifier_method = meth
      end

      def identifier_meth
        @identifier_meth || :id
      end
    end

    module InstanceMethods
      def start_process(name, collection: ProcessDefinition::Collection.instance)
        instance = collection.process_definition_for(name)
        process = instance.build(entity: self)
        self.class.process_cache.process_attribute_for(name).apply_attributes(entity: self, process: process)
        yield(process) if block_given?
        process
      end

      def __process_for(identifier)
        return nil unless identifier
        instance = Storage.instance.current_storage.fetch_process(
          identifier: identifier
        )
        if instance
          instance.set_entity(self)
          instance.wrapper
        end
      end
    end
  end
end
