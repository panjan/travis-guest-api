require 'travis/guest-api/app'

class Travis::GuestApi::App
  class Middleware
    class Rewrite < Sinatra::Base #Middleware

      before do
        remove_job_id_part
      end

      def remove_job_id_part
        if env['PATH_INFO'].sub(/\A\/jobs\/(\d+)(?=\/)/, '')
          env['job_id'] = $1
        end
      end
    end
  end
end
