module SungradeWorkflow
  class Storage
    class MemStore
      def bootstrap!
        require "sungrade_workflow/models/memory"
      end

      def transaction
        yield
      end

      def create_process(**stuff)
        puts "yet to be created"
        require "pry"; binding.pry; 1
      end
    end
  end
end
