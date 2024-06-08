require "json"

def diff(expected_partial, actual_partial, prefix: "", errors: [])
  expected_partial.keys.each do |key|
    if actual_partial[key]
      left_key_val = expected_partial[key]
      right_key_val = actual_partial[key]

      if left_key_val.is_a? Hash
        diff(left_key_val, right_key_val, prefix: "#{prefix}.#{key}", errors: errors)
      else
        if left_key_val != right_key_val
          errors << "#{prefix}.#{key} is different:\nExpected: #{left_key_val}\nActual: #{right_key_val}"
        end
      end
    else
      errors << "Expected #{prefix}.#{key}, but not exist"
    end
  end

  errors
end

def detect_extra(expected_partial, actual_partial, prefix: "", errors: [])
  actual_partial.keys.each do |key|
    if expected_partial[key]
      left_key_val = expected_partial[key]
      right_key_val = actual_partial[key]

      if left_key_val.is_a? Hash
        detect_extra(left_key_val, right_key_val, prefix: "#{prefix}.#{key}", errors: errors)
      end
    else
      errors << "Not Expected #{prefix}.#{key}, but exist"
    end
  end

  errors
end

exit 1 if ARGV.size < 2

expected_path = ARGV.shift
actual_path = ARGV.shift

expected = JSON.parse(File.read(expected_path))
actual = JSON.parse(File.read(actual_path))

diff_errors = diff(expected, actual)
extra_errors = detect_extra(expected, actual)
errors = diff_errors + extra_errors

if errors.size > 0
  errors.each { |e| puts e }
  exit 1
end
