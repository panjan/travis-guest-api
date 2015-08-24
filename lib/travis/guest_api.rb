require 'travis/guest-api/config'

module Travis
  module GuestApi

    class << self
      def config
        @config ||= defined?(Travis::Worker) ? Travis::Worker.config : Config.new
      end

      def setup
        @cache ||= Cache.new
      end
    end

  end
end
