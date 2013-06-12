module SpreeFishbowl
  module Middleware
    class CloseFishbowlConnection

      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body = @app.call(env)

        connection = SpreeFishbowl.connection
        connection.disconnect unless connection.nil?

        [status, headers, body]
      end

    end
  end
end
