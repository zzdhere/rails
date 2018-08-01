class ExportResult < ActiveRecord::Base
  def self.update_status(key, message, status=nil)
    r = self.find_by_job_key(key)
    r.result = message.class == Hash ? JSON.dump(message) : message
    r.status = status unless status.nil?
    r.save

    REDIS.set(key, r.result)
  end
end
