module BenchmarkHelper
  def self.init
    @_benchmark = []
    @_time0 = Time.now
  end

  def self.update(msg)
    @_benchmark << [msg, Time.now - @_time0]
    @_time0 = Time.now
  end

  def self.list
    ret = []
    sum = 0
    @_benchmark.each do |b|
      ret << ["#{b[0]}", "#{"%.3f" % b[1]}"]
      sum += b[1]
    end
    ret << ["Total", "#{"%.3f" % sum}"]
    
  end

  def self.output(split="\n")
    ret = []
    sum = 0
    @_benchmark.each do |b|
      ret << "#{b[0]}#{split}#{"%.3f" % b[1]}s"
      sum += b[1]
    end
    ret << "Total#{split} #{"%.3f" % sum}s"
    ret.join("\n")
  end
end
