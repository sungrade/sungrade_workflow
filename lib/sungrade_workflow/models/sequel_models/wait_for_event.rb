require "sungrade_workflow/models/common/wait_for_event"

module SungradeWorkflow
  module Models
    module SequelModels
      class WaitForEvent < Sequel::Model(Storage.instance.current_storage.connection[:wait_for_events])
        include Models::Common::WaitForEvent
        many_to_one :procedure
        many_to_one :root_process, :class => "SungradeWorkflow::Models::SequelModels::Process"

        def set_entity(entity)
          @entity = entity
        end

        def entity
          @entity ||= root_process.entity
        end

        def task_for(nme)
          nil
        end

        def available_tasks(*names)
          nil
        end

        def completed_tasks(*names)
          nil
        end

        def waiting_events(*names)
          if names.any?
            return self if available? && names.map(&:to_s).include?(name)
          else
            return self if available?
          end
        end

        def start!(**opts)
          self.class.db.transaction do
            dispatch_and_make_available!(**opts)
            maybe_autocomplete(**opts)
            self.save
          end
        end

        def complete!(**opts)
          self.class.db.transaction do
            participant_complete!(**opts) do
              update(status: "complete")
            end
            parent.walk!(**opts)
          end
        end

        def skip!(**opts)
          self.class.db.transaction do
            participant_skip!(**opts) do
              update(status: "skipped")
            end
          end
        end

        def rollback!(**opts)
          raise UnableToRollback.new("#{name} is not complete") unless complete?
          self.class.db.transaction do
            participant_rollback!(**opts) do
              if position == 0
                set(status: "rolling_back")
                parent.rollback_from_child!(self, **opts)
                if parent.available?
                  dispatch_and_make_available!(**opts)
                  maybe_autocomplete(**opts)
                else
                  set(status: "pending")
                end
              else
                dispatch_and_make_available!(**opts)
                maybe_autocomplete(**opts)
              end
            end
            self.save
          end
        end

        def rollback_from_parent!(**opts)
          return unless status_complete?
          self.class.db.transaction do
            participant_rollback!(**opts) do
              update(status: "pending")
            end
          end
        end

        def dispatch_and_make_available!(**opts)
          participant_dispatch!(**opts) do
            set(status: "dispatched")
          end
          participant_available!(**opts) do
            set(status: "available")
          end
        end

        def maybe_autocomplete(**opts)
          if auto_complete?
            participant_complete!(**opts) do
              set(status: "complete")
            end
          end
        end

        def parent
          procedure
        end
      end
    end
  end
end
