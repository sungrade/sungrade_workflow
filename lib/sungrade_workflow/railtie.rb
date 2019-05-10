module SungradeWorkflow
  class Railtie < ::Rails::Railtie
    initializer "sungrade_rails_toolkit.insert_middleware" do |app|
      if Rails.env.development?
        app.config.middleware.use SungradeWorkflow::Middleware

        if ActiveSupport.const_defined?(:Reloader) && ActiveSupport::Reloader.respond_to?(:to_complete)
          ActiveSupport::Reloader.to_complete do
            SungradeWorkflow.clear!
          end
        elsif ActionDispatch.const_defined?(:Reloader) && ActionDispatch::Reloader.respond_to?(:to_cleanup)
          ActionDispatch::Reloader.to_cleanup do
            SungradeWorkflow.clear!
          end
        end
      end
    end
  end
end
