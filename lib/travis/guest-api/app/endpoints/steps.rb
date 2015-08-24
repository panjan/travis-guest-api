require 'travis/guest-api/app/base'

class Travis::GuestApi::App::Endpoints
  class Steps < Travis::GuestApi::App::Base

    before do
      @job_id = env['job_id']
      @reporter = env['reporter']
    end

    #calls TestStepResult.write_result through amqp
    post '/steps' do
      halt 422, { error: 'Keys name, classname, result are mandatory!' }.to_json unless
        params['name'] and params['classname'] and params['result']
      params['uuid'] = SecureRandom.uuid
      sanitized_payload = params.slice('uuid', 'name', 'classname', 'result', 'duration', 'test_data')
      @reporter.send_tresult(@job_id, sanitized_payload)
      # https://github.com/SamSaffron/lru_redux ?
      #Cache.put(@job_id,payload['uuid'], sanitized_payload)
    end

    get 'steps/:id' do
      #Cache.get(@job_id, params[:id])
    end

    put 'steps/:id' do
      halt 422, { error: 'Keys name, classname are mandator!' }.to_json unless
        params['name'] and params['classname']
      sanitized_payload = params.slice('id', 'name', 'classname', 'result', 'duration', 'test_data')
      @reporter.send_tresult_update(@job_id, sanitized_payload)
      #Cache.put(@job_id,payload['id'], sanitized_payload)
    end

  end
end
