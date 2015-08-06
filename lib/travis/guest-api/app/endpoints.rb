require "sinatra/multi_route"

module Travis::GuestApi
  class App
    class Endpoints < Sinatra::Base
      register Sinatra::MultiRoute

      set :prefix, '/'

      before do
        env['rack.logger'] = Travis.logger
        env['rack.errors'] = Travis.logger.instance_variable_get(:@logdev).dev rescue nil

        @job_id = env['job_id']
        @reporter = env['reporter']
        @msg_handler = env['msg_handler']

      end

      after do
        content_type :json unless content_type
      end

      get '/' do
        content_type :text
        "Gest API, see docs"
      end

      get '/uptime' do
        status 204
      end

      post '/logs' do
        payload = JSON.parse(request.body.read).slice('job_id', 'message')
        halt 422, { error: 'Wrong job_id!' }.to_json if params['job_id'] and (@job_id != params['job_id'].to_i)
        halt 422, { error: 'Key message and number must be passed'}.to_json unless payload['message']
        @reporter.send_log(@job_id, payload["message"])
        { success: true }.to_json
      end

      post '/finished' do
        payload = JSON.parse(request.body.read).slice('job_id', 'message')
        halt 422, { error: 'Wrong job_id!' }.to_json if params['job_id'] and (@job_id != params['job_id'].to_i)
        @msg_handler.call(event: 'finished')
        { success: true }.to_json
      end

      #calls TestStepResult.write_result through amqp
      post '/testcases' do
        payload = JSON.parse(request.body.read)
        halt 422, { error: 'Wrong job_id!' }.to_json if params['job_id'] and (@job_id != params['job_id'].to_i)
        halt 422, { error: 'Keys name, classname, result are mandator!' }.to_json unless
          payload['name'] and payload['classname'] and payload['result']
        @reporter.send_tresult(@job_id, payload.slice('name', 'classname', 'result', 'duration', 'test_data'))
      end

      put 'testcases/:id' do
        payload = JSON.parse(request.body.read)
        halt 422, { error: 'Wrong job_id!' }.to_json if params['job_id'] and (@job_id != params['job_id'].to_i)
        halt 422, { error: 'Keys name, classname are mandator!' }.to_json unless
          payload['name'] and payload['classname']
        @reporter.send_tresult_update(@job_id, payload.slice('name', 'classname', 'result', 'duration', 'test_data'))
      end



      #post '/jobs/:job_id/testcases/upload', '/testcases/upload' do
      #end




      ## @params
      ##   ssh:
      #     * keep_disconnected (=switch to api)
      #     * retry_on_disconnect
      #
      #put '/jobs/:job_id/communication' do
      #end

      #  * => zapise retry_on_disconnect pokud je ssh
      #  * exec "..." at ... retry to ...  # mozno nastavit co spusti az masina nabootuje (za x minut, a zkouset max y minut)
      #post '/jobs/:job_id/restart' do
      #end





    end
  end
end
