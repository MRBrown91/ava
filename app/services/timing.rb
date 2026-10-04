class Timing
  def self.start_ms
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def self.elapsed_ms(start)
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).to_i
  end
end
