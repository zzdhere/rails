# God.watch do |w|
#   w.name = "delayed_job"
#   w.start = "/home/raisethink/fmis_rpt/backend/trunk/bin/delayed_job start"
#   w.keepalive
# end

# God: Ruby进程监控框架
# 参考: https://ruby-china.org/topics/21354
# 启动: god -c scripts/god/god_config.god
# 调试启动: god -c scripts/god/god_config.god -D

RAILS_ROOT = "/home/raisethink/fmis_rpt/backend/trunk"
#RAILS_ROOT = "/Users/lizl/work/pioneer_am/pcia-backend"
RAILS_ENV = "development"

# name: 唯一的, 重启、停止时使用 god restart delayed_job-0 、 god stop delayed_job-0
# pid_file: god监视的pid
# behavior: 如果非正常情况进程停止了,但是pid还存在,god会清掉
# keepalive: 保持这个进程alive

# 监控delayed_job
# 我们要启动4个,这4个进程pid的命名格式为delayed_job.0.pid至delayed_job.3.pid
4.times do |num|
  God.watch do |w|
    w.name = "delayed_job-#{num}"
    w.pid_file = "#{RAILS_ROOT}/tmp/pids/delayed_job.#{num}.pid"
    w.start = "cd #{RAILS_ROOT} && RAILS_ENV=#{RAILS_ENV} ruby bin/delayed_job --identifier=#{num} start"
    w.stop = "cd #{RAILS_ROOT} && RAILS_ENV=#{RAILS_ENV} ruby bin/delayed_job --identifier=#{num} stop"
    #w.restart = "kill -TERM `cat #{RAILS_ROOT}/tmp/pids/delayed_job.#{num}.pid`"
    w.restart = "cd #{RAILS_ROOT} && rails runner -e development 'DelayedJobService.restart(#{num})'"
    w.log = File.join(RAILS_ROOT, "log/god_delayed_job.log")
    w.behavior(:clean_pid_file)
    w.keepalive
    #没1分钟去扫一下进程的状态
    w.interval = 1.minutes

    # w.restart_if do |restart|
    #   #当delayed job使用内存超过500M时，调用DelayedJobService.restart判断重启。
    #   restart.condition(:memory_usage) do |c|
    #    c.above = 500.megabytes
    #   end
    # end

  end
end