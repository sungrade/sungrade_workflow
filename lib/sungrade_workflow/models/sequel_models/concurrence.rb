require "sungrade_workflow/models/common/concurrence"

module SungradeWorkflow
  module Models
    module SequelModels
      class Concurrence < Sequel::Model(Storage.instance.current_storage.connection[:concurrences])
        include Models::Common::Concurrence
        many_to_one :process
        many_to_one :concurrence
        one_to_many :concurrences
        many_to_one :procedure
        one_to_many :procedures
        many_to_one :root_process, :class => "SungradeWorkflow::Models::SequelModels::Process"

        def set_entity(entity)
          @entity = entity
          children.each { |child| child.set_entity(entity) }
        end

        def entity
          @entity ||= root_process.entity
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
              children.each do |child|
                child.skip!(**opts) unless child.complete?
              end
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

        def skip!(**opts)
          self.class.db.transaction do
            participant_skip!(**opts) do
              children.each(&:skip!)
              update(status: "skipped")
            end
          end
        end

        def rollback_from_child!(entity, **opts)
          self.class.db.transaction do
            participant_rollback!(**opts) do
              set(status: "rolling_back")

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

        def target_for_rollback_process(to:, from:, original_from:)
          return self if cursor == to
          child_match = children.find { |child| child.cursor == to && child.position <= from.position }
          return child_match if child_match
          parent.target_for_rollback_process(to: to, from: self, original_from: original_from)
        end

        def rollback_to!(to:, from:, **opts)
          self.class.db.transaction do
            if self.cursor == to
              # children have been rolled back already do we need to do anything?
            else
              child_match = children.find { |child| child.cursor == to }
              if child_match
                # children have been rollback back already again
              else
                participant_rollback!(**opts) do
                  set(status: "rolling_back")
                  children.each { |child| child.rollback_from_parent!(**opts) }
                  parent.rollback_to!(to: to, from: self, **opts)

                  if parent.process? && position == 0
                    if parent.available?
                      dispatch_and_make_available!(**opts)
                    else
                      set(status: "pending")
                    end
                  elsif parent.concurrence? && !parent.children_complete?
                    if parent.available?
                      dispatch_and_make_available!(**opts)
                    else
                      set(status: "pending")
                    end
                  else
                    dispatch_and_make_available!(**opts)
                  end
                end
              end
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
          end
          if children_complete?
            children.each do |child|
              child.skip!(**opts) unless child.complete?
            end
            participant_complete!(auto_complete: true, **opts) do
              set(status: "complete")
            end
          end
        end

        def task_for(name)
          val = nil
          children.each do |child|
            val = child.task_for(name)
            break if val
          end
          val
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

        def complete?
          status_complete? && children_complete?
        end

        def children_complete?
          if self.count
            children.count(&:complete?) >= self.count
          else
            children.all?(&:complete?)
          end
        end

        def parent
          concurrence || procedure || process
        end

        def children
          [
            concurrences,
            procedures
          ].flatten.sort_by(&:position)
        end
      end
    end
  end
end
