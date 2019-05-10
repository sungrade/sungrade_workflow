require_relative "storage/mem_store"
require_relative "storage/sequel_model_store"

module SungradeWorkflow
  class Storage
    class << self
      def instance
        @instance ||= new
      end

      def memory!
        instance.memory!
      end

      def sequel_adapter(connection)
        instance.sequel_adapter(connection)
      end

      def bootstrap!
        instance.bootstrap!
      end
    end

    def current_storage
      @current_storage
    end

    def fetch_process(**args)
      current_storage.fetch_process(**args)
    end

    def create_concurrence(**args)
      current_storage.create_concurrence(**args)
    end

    def create_process(**args)
      current_storage.create_process(**args)
    end

    def create_procedure(**args)
      current_storage.create_procedure(**args)
    end

    def create_rollback_process(**args)
      current_storage.create_rollback_process(**args)
    end

    def create_task(**args)
      current_storage.create_task(**args)
    end

    def create_wait_for_event(**args)
      current_storage.create_wait_for_event(**args)
    end

    def bootstrap!
      current_storage.bootstrap!
    end

    def memory!
      @current_storage = MemStore.new
    end

    def sequel_adapter(connection)
      @current_storage = SequelModelStore.new(connection)
    end
  end
end
