require "sungrade_workflow/models/common/process"

module SungradeWorkflow
  module Models
    module SequelModels
      class Process < Sequel::Model(Storage.instance.current_storage.connection[:processes])
        include Models::Common::Process
        one_to_many :procedures
        one_to_many :concurrences
        attr_writer :entity

        class << self
          def fetch_tree(identifier:, **)
            where(
              identifier: identifier
            ).eager(
              procedures: [
                :tasks,
                {
                  concurrences: {
                    procedures: [
                      :tasks,
                      :concurrences
                    ],
                    concurrences: {
                      procedures: [
                        :tasks
                      ]
                    }
                  }
                }
              ]
            ).all.first
          end
        end

        def start!(**opts)
          self.class.db.transaction do
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
            self.save
          end
        end

        def walk!(**opts)
          self.class.db.transaction do
            if children_complete?
              participant_complete!(**opts) do
                update(status: "complete")
              end
            else
              next_child = children.find { |child| !child.complete? }
              next_child.start!(**opts)
            end
          end
        end

        def rollback_from_child!(entity, **opts)
          self.class.db.transaction do
            walk!(**opts)
          end
        end

        def target_for_rollback_process(to:, from:, original_from:)
          return self if cursor == to
          child_match = children.find { |child| child.cursor == to && child.position <= from.position }
          return child_match if child_match
          raise MissingCursor.new("No valid cursor found for #{to}")
        end

        def rollback_to!(to:, from:, **opts)
          self.class.db.transaction do
            if self.cursor == to
              children_between = children.select do |child|
                child.position > child_match.position && child.position < from.position
              end
              children_between.each { |child| child.rollback_from_parent!(**opts) }
            end
          end
        end

        def set_entity(ent)
          @entity = ent
          unless entity_matches?(ent)
            update(
              entity_id: ent.send(ent.class.identifier_meth),
              entity_class: ent.class
            )
          end
          children.each { |child| child.set_entity(ent) }
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

        def entity
          @entity ||= Configuration.find_entity(self.entity_id, self.entity_class)
        end

        def complete?
          status_complete? && children_complete?
        end

        def children_complete?
          children.all?(&:complete?)
        end

        def entity_matches?(ent)
          entity_id == ent.send(ent.class.identifier_meth) && entity_class == ent.class
        end

        def children
          [
            procedures,
            concurrences
          ].flatten.sort_by(&:position)
        end
      end
    end
  end
end
