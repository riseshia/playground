require_relative 'local_var_extractor'

class ThreadParallel
  def self.run(file_path, iterations, thread_count = 8)
    results = []
    threads = []

    iterations_per_thread = iterations / thread_count
    remainder = iterations % thread_count

    thread_count.times do |i|
      iterations_for_this_thread = iterations_per_thread
      iterations_for_this_thread += 1 if i < remainder

      threads << Thread.new do
        thread_results = []
        iterations_for_this_thread.times do
          local_vars = LocalVarExtractor.extract(file_path)
          thread_results << local_vars
        end
        thread_results
      end
    end

    threads.each do |thread|
      results.concat(thread.value)
    end

    results
  end
end
