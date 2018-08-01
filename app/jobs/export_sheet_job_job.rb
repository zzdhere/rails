# class ExportSheetJobJob < ActiveJob::Base
#   queue_as :default

#   def perform(*args)
#     # Do something later
#   end
# end


class ExportSheetJobJob < Struct.new(:report_id, :months, :styles, :key)
  def enqueue(job)
    # ExportResult.create job_key: key, status: 2
    Delayed::Worker.logger.info job.class
    Delayed::Worker.logger.info $0
    key
  end

  def perform
    # att_id = FmisReport::ReportHelper.make_reports(reports, months, key)
    # res = ExportResult.where('job_key=?', key).take
    # res.file_id = att_id
    # res.status = 0
    # res.save
    REDIS.set "#{key}-#{report_id}-RESULT", JSON.dump({
      success: 1,
      data: {}
    })
  end

  def success(job)
  #   # res = ExportResult.where('job_id=?', job.id).take
  #   # res.status = 0
  #   # res.save
  #   res = ExportResult.where('job_key=?', key).take
  #   res.status = 0
  #   res.save
    clean_report_queue
  end

  def error(job, exception)
    # res = ExportResult.where('job_key=?', key).take
    # res.status = 1
    # res.result = exception.message
    # res.save
    REDIS.set "#{key}-#{report_id}-RESULT", JSON.dump({
      success: 0,
      errmsg: exception.message
      data: {}
    })
    clean_report_queue
  end

  def clean_report_queue
    REDIS.lrem "#{key}-REPORTS", 0, report_id
  end
end