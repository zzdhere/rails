class ImportJob < Struct.new(:filename, :key, :module_name)
  def enqueue(job)
    ExportResult.create job_key: key, status: 2, result: 'File uploaded. Reading...'
    key
  end

  def perform
    # att_id = FmisReport::ReportHelper.make_reports(reports, months)
    cls = FmisReport.const_get(module_name)
    cls.import_file(filename, key)
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