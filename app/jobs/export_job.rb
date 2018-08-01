# class ExportJob < ActiveJob::Base
#   queue_as :default

#   def perform(*args)
#     # Do something later
#   end
# end


class ExportJob < Struct.new(:reports, :months, :key)
  def enqueue(job)
    ExportResult.create job_key: key, status: 2
    key
  end

  def perform
    att_id = FmisReport::ReportHelper.make_reports(reports, months, key)
    res = ExportResult.where('job_key=?', key).take
    res.file_id = att_id
    res.status = 0
    res.save
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
    res = ExportResult.where('job_key=?', key).take
    res.status = 1
    res.result = exception.message
    res.save
  end
end