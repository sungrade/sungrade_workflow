require 'rack/body_proxy'

module SungradeWorkflow
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      SungradeWorkflow.begin!

      response = @app.call(env)

      returned = response << Rack::BodyProxy.new(response.pop) do
        SungradeWorkflow.clear!
      end
    ensure
      unless returned
        SungradeWorkflow.clear!
      end
    end
  end
end
