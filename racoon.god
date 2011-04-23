# Godfile for racoon

[ 1 ].each do |instance|
  name = "racoon-#{instance}"
  pid_file = "/var/run/#{name}.pid"

  God.watch do |w|
    w.name = name
    w.interval = 30.seconds
    w.start = "/fracas/deploy/racoon/bin/racoond -d --beanstalk 127.0.0.1:11300 --pid #{pid_file} --log /var/log/#{name}.log"
    w.stop = "kill -15 `cat #{pid_file}`"
    w.start_grace = 10.seconds
    w.pid_file = pid_file

    w.behavior(:clean_pid_file)

    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.interval = 5.seconds
        c.running = false
      end
    end

    w.lifecycle do |on|
      on.condition(:flapping) do |c|
        c.to_state = [:start, :stop, :start]
        c.times = 5
        c.within = 5.minutes
        c.transition = :unmonitored
        c.retry_in = 10.minutes
        c.retry_times = 5
        c.retry_within = 2.hours
      end
    end
  end
end
