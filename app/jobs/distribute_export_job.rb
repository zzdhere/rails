# class DistributeExportJob < ActiveJob::Base
#   queue_as :default

#   def perform(*args)
#     # Do something later
#   end
# end


class DistributeExportJob < Struct.new(:reports, :months, :key)
  def enqueue(job)
    # ExportResult.create job_key: key, status: 2
    # key
    REDIS.set key, JSON.dump({status: 2, message: 'Beginning...'})
  end

  def perform
    Delayed::Worker.logger.info("="*80)
    Delayed::Worker.logger.info($0)
    Delayed::Worker.logger.info("MessagePack::DefaultFactory.registered_types: #{MessagePack::DefaultFactory.registered_types}")
    Delayed::Worker.logger.info("="*80)
    att_id = FmisReport::ReportHelper.distribute_make_reports(reports, months, key)
    # res = ExportResult.where('job_key=?', key).take
    # res.file_id = att_id
    # res.status = 0
    # res.save
    REDIS.set key, JSON.dump({status: 0, file_id: att_id})
  end

  # def success(job)
  #   # res = ExportResult.where('job_id=?', job.id).take
  #   # res.status = 0
  #   # res.save
  #   res = ExportResult.where('job_key=?', key).take
  #   res.status = 0
  #   res.save
  # end
  def error(job, exception)
    REDIS.set key, JSON.dump({status: 1, errmsg: exception.message})
  end


  # def failure(job)
  #   REDIS.set key, JSON.dump({status: 1, errmsg: 'failure'})
  # end
end