require 'spec_helper'
require 'rack/test'
require 'travis/guest-api/app/middleware/rewrite'

describe Travis::GuestApi::App::Middleware::Rewrite do

  include Rack::Test::Methods

  def app
    Travis::GuestApi::App.new(1, reporter, &callback)
  end

  let(:reporter) { double(:reporter) }
  let(:callback) { ->(x) { } }

  it 'rewrites job_id part to environment' do
    job_id = 123
    get("/jobs/#{job_id}/logs", {})
    expect(last_request.env['job_id']).to eq(job_id.to_s)
  end
end
