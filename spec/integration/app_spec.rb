require 'spec_helper'
require 'ostruct'

require 'travis/guest-api/app'
require 'rack/test'

module Travis::GuestApi
  describe App do
    include Rack::Test::Methods

    def app
      Travis::GuestApi::App.new(1, reporter, &callback)
    end

    let(:reporter) { double(:reporter) }
    let(:callback) { ->(x) { } }

    describe 'GET /uptime' do
      it 'returns 204' do
        response = get '/uptime'
        expect(response.status).to eq(204)
      end
    end

    describe 'POST /logs' do
      let(:post_data1) { { job_id: 1, message: 'my message1' } }
      let(:post_data2) { { job_id: 1, message: 'my message2' } }
      it 'sends data to pusher' do

        expect(reporter).to receive(:send_log).with(1, post_data1[:message])
        expect(reporter).to receive(:send_log).with(1, post_data2[:message])

        response = post '/logs', post_data1.to_json, "CONTENT_TYPE" => "application/json"
        expect(response.status).to eq(200)

        response = post '/logs', post_data2.to_json, "CONTENT_TYPE" => "application/json"
        expect(response.status).to eq(200)
      end

      it 'responds with 422 when message is missing' do
        response = post '/logs', { job_id: 1 }.to_json, "CONTENT_TYPE" => "application/json"
        expect(response.status).to eq(422)
      end

      it 'responds with 422 on job_id mismatch' do
        response = post '/logs', { job_id: 2 }.to_json, "CONTENT_TYPE" => "application/json"
        expect(response.status).to eq(422)
      end
    end

    describe 'POST /jobs/:job_id/logs' do
      it 'responds with 422 when passed job_id is wrong' do
        response = post '/jobs/2/logs', { job_id: 1 }.to_json, "CONTENT_TYPE" => "application/json"
        expect(response.status).to eq(422)
      end
    end

    context 'testcase' do
      let(:testcase) {
        {
          'job_id'    => 1,
          'name'      => 'testName',
          'classname' => 'className',
          'result'    => 'success',
        }
      }
      let(:testcase_with_data) { testcase.update('test_data' => { 'any_content' => 'xxx' }, 'duration' => 56) }


      describe 'POST /testcases' do
        it 'sends data to the pusher' do
          expect(reporter).to receive(:send_tresult) { |job_id, arg|
            expect(job_id).to eq(testcase['job_id'])
            e = testcase.dup
            e.delete 'job_id'
            expect(arg).to eq(e)
          }
          expect(reporter).to receive(:send_tresult) { |job_id, arg|
            e = testcase_with_data.dup
            e.delete 'job_id'
            expect(arg).to eq(e)
          }

          response = post '/testcases', testcase.to_json, "CONTENT_TYPE" => "application/json"
          expect(response.status).to eq(200)

          response = post '/testcases', testcase_with_data.to_json, "CONTENT_TYPE" => "application/json"
          expect(response.status).to eq(200)
        end

        it 'responds with 422 when name, classname or result is missing' do
          without_name = testcase.dup
          without_name.delete 'name'
          response = post '/testcases', without_name.to_json, "CONTENT_TYPE" => "application/json"
          expect(response.status).to eq(422)

          without_classname = testcase.dup
          without_classname.delete 'classname'
          response = post '/testcases', without_classname.to_json, "CONTENT_TYPE" => "application/json"
          expect(response.status).to eq(422)

          without_result = testcase.dup
          without_result.delete 'result'
          response = post '/testcases', without_result.to_json, "CONTENT_TYPE" => "application/json"
          expect(response.status).to eq(422)
        end
      end

      describe 'POST /jobs/:job_id/testcases' do
        it 'responds with 422 when passed job_id is wrong' do
          response = post '/jobs/2/testcases', testcase.to_json, "CONTENT_TYPE" => "application/json"
          expect(response.status).to eq(422)
        end
      end
    end

    describe 'POST /finished' do
      it 'call callback with event: finished' do
        expect(callback).to receive(:call).with(event: 'finished')

        response = post '/finished', {}.to_json, "CONTENT_TYPE" => "application/json"
        expect(response.status).to eq(200)
      end
    end

  end
end
