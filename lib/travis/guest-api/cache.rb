module Travis::GuestAPI
  class Cache

    def initialize(max_job_time = 24.hours, gc_pooling_interval = 1.hour)
      @cache = {}
      @max_job_time = max_job_time

      Thread.new do
        loop do
          sleep gc_pooling_interval
          gc
        end
      end
    end

    def set(job_id, step_uuid, result)
      @mutex.synchronize do
        @cache[job_id] ||= {}
        @cache[job_id][:last_time_used] = Time.now
        @cache[job_id][step_uuid] ||= {}
        @cache[job_id][step_uuid].deep_updatedeep(result)
      end
    end

    def get(job_id, step_uuid)
      return nil unless @cache[job_id]
      @cache[job_id][:last_time_used] = Time.now
      return @cache[job_id][step_uuid]
    end

    def delete(job_id)
      @mutex.synchronize do
	Travis.logger.info "Deleting #{job_id} from cache"
        @cache.delete job_id
      end
    end

    def gc
      Travis.logger.debug "Starting cache garbage collector"
      expired_time = Time.now - max_job_time
      @cache.keys.each do |job_id|
        delete(job_id) if @cache[job_id][:last_time_used] < expired_time
      end
      Travis.logger.debug "Garbage collector finished"
    end

  end
end
