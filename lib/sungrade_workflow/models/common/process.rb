module SungradeWorkflow
  module Models
    module Common
      module Process
        def concurrence?; false; end
        def procedure?; false; end
        def process?; true; end
        def task?; false; end
        def wait_for_event?; false; end

        def wrapper
          @wrapper ||= ::SungradeWorkflow::Process.new(self)
        end

        def participant
          wrapper.participant
        end

        def available?
          status == "available"
        end

        def skipped?
          status == "skipped"
        end

        def pending?
          status == "pending"
        end

        def status_complete?
          status == "complete" || skipped?
        end

        def participant_dispatch!(**opts)
          participant.before_dispatch(**opts)
          yield if block_given?
          participant.after_dispatch(**opts)
        end

        def participant_available!(**opts)
          participant.before_available(**opts)
          yield if block_given?
          participant.after_available(**opts)
        end

        def participant_skip!(**opts)
          participant.before_skip(**opts)
          yield if block_given?
          participant.after_skip(**opts)
        end

        def participant_complete!(**opts)
          participant.before_complete(**opts)
          participant.up(**opts)
          yield if block_given?
          participant.after_complete(**opts)
        end

        def participant_rollback!(**opts)
          participant.before_rollback(**opts)
          participant.down(**opts)
          yield if block_given?
          participant.after_rollback(**opts)
        end
      end
    end
  end
end
