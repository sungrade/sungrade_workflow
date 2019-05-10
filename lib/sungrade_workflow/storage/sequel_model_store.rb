module SungradeWorkflow
  class Storage
    class SequelModelStore
      attr_reader :connection

      def initialize(connection)
        @connection = connection
      end

      def bootstrap!
        Sequel::Migrator.run(connection, File.expand_path('../../db/sequel_migrations', __FILE__), :use_transactions=>true)
        require "sungrade_workflow/models/sequel_model"
      end

      def transaction
        connection.transaction do
          yield
        end
      end

      def fetch_process(identifier:, **)
        Models::SequelModels::Process.fetch_tree(
          identifier: identifier
        )
      end

      def create_process(entity:, blk:, name:, version:, participant_class:)
        connection.transaction do
          Models::SequelModels::Process.create(
            name: name,
            version: version,
            entity_id: entity.send(entity.class.identifier_meth),
            entity_class: entity.class,
            participant_class: participant_class,
            identifier: SecureRandom.uuid,
            status: :pending,
          )
        end
      end

      def create_procedure(process:, parent:, position:, blk:, participant_class:, **opts)
        connection.transaction do
          Models::SequelModels::Procedure.create(
            root_process_id: process.id,
            position: position,
            participant_class: participant_class,
            status: :pending,
            **options_from(parent),
            **opts
          )
        end
      end

      def create_task(process:, procedure:, position:, name:, participant_class:, **opts)
        connection.transaction do
          Models::SequelModels::Task.create(
            root_process_id: process.id,
            position: position,
            procedure: procedure,
            name: name,
            participant_class: participant_class,
            status: :pending,
            **opts
          )
        end
      end

      def create_wait_for_event(process:, procedure:, position:, name:, participant_class:, **opts)
        connection.transaction do
          Models::SequelModels::WaitForEvent.create(
            root_process_id: process.id,
            position: position,
            procedure: procedure,
            name: name,
            participant_class: participant_class,
            status: :pending,
            **opts
          )
        end
      end

      def create_rollback_process(process:, procedure:, position:, name:, participant_class:, to:, **opts)
        connection.transaction do
          Models::SequelModels::RollbackProcess.create(
            root_process_id: process.id,
            position: position,
            procedure: procedure,
            name: name,
            to: to,
            participant_class: participant_class,
            status: :pending,
            **opts
          )
        end
      end

      def create_concurrence(process:, parent:, position:, blk:, participant_class:, **opts)
        connection.transaction do
          Models::SequelModels::Concurrence.create(
            root_process_id: process.id,
            status: :pending,
            position: position,
            participant_class: participant_class,
            **options_from(parent),
            **opts
          )
        end
      end

      def options_from(parent)
        if parent.is_a?(Models::SequelModels::Procedure)
          {procedure_id: parent.id}
        elsif parent.is_a?(Models::SequelModels::Process)
          {process_id: parent.id}
        elsif parent.is_a?(Models::SequelModels::Concurrence)
          {concurrence_id: parent.id}
        else
          {}
        end
      end
    end
  end
end
