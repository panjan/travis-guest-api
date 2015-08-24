require 'spec_helper'
require 'ostruct'

require 'rack/test'

module Travis::GuestApi
  describe App do
    include Rack::Test::Methods

    def app
      Travis::GuestApi::App.new(1, reporter, &callback)
    end

    let(:reporter) { double(:reporter) }
    let(:callback) { ->(x) { } }

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

      describe 'POST /steps' do
        it 'sends data to the reporter' do
          expect(reporter).to receive(:send_tresult) { |job_id, arg|
            expect(job_id).to eq(testcase['job_id'])
            e = testcase.dup
            e.delete 'job_id'
            expect(arg['uuid']).to be_a(String)
            e['uuid'] = arg['uuid']
            expect(arg).to eq(e)
          }
          expect(reporter).to receive(:send_tresult) { |job_id, arg|
            e = testcase_with_data.dup
            e.delete 'job_id'
            arg.delete 'uuid'
            expect(arg).to eq(e)
          }

          response = post '/api/v2/steps', testcase.to_json, "CONTENT_TYPE" => "application/json"
          expect(response.status).to eq(200)

          response = post '/api/v2/steps', testcase_with_data.to_json, "CONTENT_TYPE" => "application/json"
          expect(response.status).to eq(200)
        end

        it 'responds with 422 when name, classname or result is missing' do
          without_name = testcase.dup
          without_name.delete 'name'
          response = post '/api/v2/steps', without_name.to_json, "CONTENT_TYPE" => "application/json"
          expect(response.status).to eq(422)

          without_classname = testcase.dup
          without_classname.delete 'classname'
          response = post '/api/v2/steps', without_classname.to_json, "CONTENT_TYPE" => "application/json"
          expect(response.status).to eq(422)

          without_result = testcase.dup
          without_result.delete 'result'
          response = post '/api/v2/steps', without_result.to_json, "CONTENT_TYPE" => "application/json"
          expect(response.status).to eq(422)
        end
      end

      describe 'POST /jobs/:job_id/steps' do
        it 'responds with 422 when passed job_id is wrong' do
          response = post '/api/v1/jobs/2/steps', testcase.to_json, "CONTENT_TYPE" => "application/json"
          expect(response.status).to eq(422)
        end
      end
    end
  end
end
