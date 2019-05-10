module SungradeWorkflow
  class Configuration
    attr_accessor :workflows_directory
    class << self
      def instance
        @instance ||= new
      end

      def evaluate(blk)
        instance.instance_eval(&blk)
      end

      def validate!
        instance.validate!
      end

      def begin!
        instance.begin!
      end

      def find_entity(id, klass)
        instance.find_entity(id, klass)
      end
    end

    def validate!
      raise ConfigurationError.new("No storage method set") unless @storage
    end

    def to_find_entity=(&blk)
      @to_find_entity = blk
    end

    def begin!
      if workflows_directory
        Dir.glob(
          File.join(workflows_directory, "**/*.rb")
        ) do |file|
          load file
        end
      end
    end

    def find_entity(id, klass)
      if @to_find_entity
        @to_find_entity.call(id, klass)
      else
        Module.const_get(klass).find(id: id)
      end
    end

    def storage=(arg)
      @storage = arg
      if arg.instance_of?(Sequel::Postgres::Database)
        Storage.sequel_adapter(arg)
      elsif arg == :memory
        Storage.memory!
      else
        raise "Unknown storage type"
      end
      @storage
    end
  end
end
