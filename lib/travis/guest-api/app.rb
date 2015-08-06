require 'travis/support'
require 'travis/support/metrics'
require 'sinatra/base'

require 'travis/guest-api/app/endpoints'
require 'travis/guest-api/app/middleware/rewrite'

#require 'travis/worker'
#require 'travis/worker/reporter'
#require 'travis/worker/utils/serialization'

module Travis::GuestApi

  class App

    attr_reader :app

    def initialize(job_id, reporter = nil, &block)
      @job_id = job_id
      @reporter = reporter # || Travis::Worker::Reporter.new(P
      #  'standalone-reporter',
      #  Travis::Amqp::Publisher.jobs('builds', unique_channel: true, dont_retry: true),
      #  Travis::Amqp::Publisher.jobs('logs', unique_channel: true, dont_retry: true),
      #  Travis::Amqp::Publisher.jobs('test_results', unique_channel: true, dont_retry: true)
      #)
      @msg_handler = block

      @app = Rack::Builder.app do
        map '/' do
          use Travis::GuestApi::App::Middleware::Rewrite
          run Travis::GuestApi::App::Endpoints.new
        end
      end
    end

    def call(env)
      env['job_id'] = @job_id
      env['reporter'] = @reporter
      env['msg_handler'] = @msg_handler
      app.call(env)
    end
  end

end
