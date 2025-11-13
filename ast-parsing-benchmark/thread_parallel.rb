require_relative 'local_var_extractor'

class ThreadParallel
  def self.run(file_paths, thread_count = 8)
    results = []
    threads = []

    iterations = file_paths.size
    iterations_per_thread = iterations / thread_count
    remainder = iterations % thread_count

    current_index = 0

    thread_count.times do |i|
      iterations_for_this_thread = iterations_per_thread
      iterations_for_this_thread += 1 if i < remainder

      start_index = current_index
      end_index = current_index + iterations_for_this_thread
      current_index = end_index

      threads << Thread.new(start_index, end_index) do |start_idx, end_idx|
        thread_results = []
        (start_idx...end_idx).each do |idx|
          local_vars = LocalVarExtractor.extract(file_paths[idx])
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
