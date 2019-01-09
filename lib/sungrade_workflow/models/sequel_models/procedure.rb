require "sungrade_workflow/models/common/procedure"

module SungradeWorkflow
  module Models
    module SequelModels
      class Procedure < Sequel::Model(Storage.instance.current_storage.connection[:procedures])
        include Models::Common::Procedure
        many_to_one :process
        many_to_one :concurrence
        one_to_many :concurrences
        many_to_one :procedure
        one_to_many :procedures
        one_to_many :tasks
        one_to_many :wait_for_events
        many_to_one :root_process, :class => "SungradeWorkflow::Models::SequelModels::Process"

        def set_entity(entity)
          @entity = entity
          children.each { |child| child.set_entity(entity) }
        end

        def entity
          @entity ||= root_process.entity
        end

        def task_for(name)
          val = nil
          children.each do |child|
            val = child.task_for(name)
            break if val
          end
          val
        end

        def start!(**opts)
          self.class.db.transaction do
            dispatch_and_make_available!(**opts)
            self.save
          end
        end

        def walk!(**opts)
          self.class.db.transaction do
            if children_complete?
              participant_complete!(**opts) do
                update(status: "complete")
              end
              parent.walk!(**opts)
            else
              next_child = children.find { |child| !child.complete? }
              next_child.start!(**opts)
            end
          end
        end

        def rollback_from_child!(entity, **opts)
          self.class.db.transaction do
            participant_rollback!(**opts) do
              set(status: "rolling_back")
              children_after = children.select { |child| child.position > entity.position }
              children_after.each { |child| rollback_from_parent!(**opts) }

              if parent.process? && position == 0
                parent.rollback_from_child!(self, rolling_back: true, **opts)
                if parent.available?
                  dispatch_and_make_available!(**opts)
                else
                  set(status: "pending")
                end
              elsif parent.concurrence? && !parent.children_complete?
                parent.rollback_from_child!(self, rolling_back: true, **opts)
                if parent.available?
                  dispatch_and_make_available!(**opts)
                else
                  set(status: "pending")
                end
              else
                dispatch_and_make_available!(**opts)
              end
            end
            self.save
          end
        end

        def rollback_from_parent!(**opts)
          return unless status_complete?
          self.class.db.transaction do
            participant_rollback!(**opts) do
              set(status: "rolling_back")
              children.each { |child| child.rollback_from_parent!(**opts) }
              set(status: "pending")
            end
          end
        end

        def skip!(**opts)
          self.class.db.transaction do
            participant_skip!(**opts) do
              children.each(&:skip!)
              update(status: "skipped")
            end
          end
        end

        def dispatchable?
          ["rolling_back", "pending"].include?(status)
        end

        def dispatch_and_make_available!(**opts)
          return unless dispatchable?
          participant_dispatch!(**opts) do
            set(status: "dispatched")
          end
          participant_available!(**opts) do
            set(status: "available")
          end
          children.each do |child|
            child.start!(**opts)
            break unless child.complete?
          end
          if children_complete?
            participant_complete!(auto_complete: true, **opts) do
              set(status: "complete")
            end
          end
        end

        def available_tasks(*names)
          children.map { |child| child.available_tasks(*names) }.compact.flatten
        end

        def completed_tasks(*names)
          children.map { |child| child.completed_tasks(*names) }.compact.flatten
        end

        def waiting_events(*names)
          children.map { |child| child.waiting_events(*names) }.compact.flatten
        end

        def parent
          concurrence || procedure || process
        end

        def complete?
          status_complete? && children_complete?
        end

        def children_complete?
          children.all?(&:complete?)
        end

        def children
          [
            tasks,
            procedures,
            concurrences,
            wait_for_events
          ].flatten.sort_by(&:position)
        end
      end
    end
  end
end
