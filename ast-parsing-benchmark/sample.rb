# Sample Ruby file for AST parsing benchmark

class User
  attr_accessor :name, :email, :age

  def initialize(name, email, age)
    @name = name
    @email = email
    @age = age
    created_at = Time.now
    user_id = generate_id
    validation_result = validate_user
  end

  def generate_id
    timestamp = Time.now.to_i
    random_part = rand(1000..9999)
    id_string = "#{timestamp}-#{random_part}"
    id_string
  end

  def validate_user
    errors = []

    if @name.nil? || @name.empty?
      error_message = "Name cannot be empty"
      errors << error_message
    end

    if @email.nil? || !@email.include?('@')
      email_error = "Invalid email format"
      errors << email_error
    end

    if @age.nil? || @age < 0
      age_error = "Invalid age"
      errors << age_error
    end

    validation_passed = errors.empty?
    validation_passed
  end

  def update_profile(new_name, new_email)
    old_name = @name
    old_email = @email

    @name = new_name if new_name
    @email = new_email if new_email

    change_log = {
      old_name: old_name,
      new_name: @name,
      old_email: old_email,
      new_email: @email
    }

    change_log
  end
end

class UserRepository
  def initialize
    @users = []
    storage_path = '/tmp/users.db'
    connection = establish_connection(storage_path)
  end

  def establish_connection(path)
    retry_count = 0
    max_retries = 3

    begin
      connection = Database.connect(path)
      connection
    rescue => e
      retry_count += 1
      error_message = "Connection failed: #{e.message}"

      if retry_count < max_retries
        sleep_duration = retry_count * 2
        sleep(sleep_duration)
        retry
      else
        raise error_message
      end
    end
  end

  def find_by_id(id)
    target_id = id.to_s
    found_user = nil

    @users.each do |user|
      user_id = user.id
      if user_id == target_id
        found_user = user
        break
      end
    end

    found_user
  end

  def find_by_email(email)
    search_email = email.downcase.strip
    results = []

    @users.each do |user|
      user_email = user.email.downcase.strip
      if user_email == search_email
        results << user
      end
    end

    results
  end

  def add_user(user)
    validation_result = user.validate_user

    if validation_result
      @users << user
      index = @users.length - 1
      success_message = "User added at index #{index}"
      { success: true, message: success_message }
    else
      error_detail = "User validation failed"
      { success: false, message: error_detail }
    end
  end

  def remove_user(id)
    initial_count = @users.count
    target_id = id.to_s

    @users.reject! do |user|
      user_id = user.id
      user_id == target_id
    end

    final_count = @users.count
    removed_count = initial_count - final_count
    removed_count > 0
  end

  def list_all_users
    user_list = []

    @users.each_with_index do |user, index|
      user_info = {
        index: index,
        name: user.name,
        email: user.email,
        age: user.age
      }
      user_list << user_info
    end

    user_list
  end
end

class UserService
  def initialize(repository)
    @repository = repository
    service_name = "UserService"
    initialized_at = Time.now
  end

  def register_user(name, email, age)
    new_user = User.new(name, email, age)
    result = @repository.add_user(new_user)

    if result[:success]
      notification_message = "Welcome #{name}!"
      send_notification(email, notification_message)
      success_data = { user: new_user, message: result[:message] }
      success_data
    else
      error_details = result[:message]
      { error: error_details }
    end
  end

  def send_notification(email, message)
    recipient = email
    content = message
    timestamp = Time.now

    notification_id = "notif-#{timestamp.to_i}"
    notification_data = {
      id: notification_id,
      recipient: recipient,
      content: content,
      sent_at: timestamp
    }

    begin
      mailer = EmailMailer.new
      delivery_result = mailer.deliver(notification_data)
      delivery_result
    rescue => e
      error_msg = "Failed to send notification: #{e.message}"
      logger.error(error_msg)
      false
    end
  end

  def update_user_info(id, name: nil, email: nil, age: nil)
    user = @repository.find_by_id(id)

    unless user
      error_text = "User not found with id: #{id}"
      return { error: error_text }
    end

    old_data = {
      name: user.name,
      email: user.email,
      age: user.age
    }

    if name
      user.name = name
      name_changed = true
    end

    if email
      user.email = email
      email_changed = true
    end

    if age
      user.age = age
      age_changed = true
    end

    new_data = {
      name: user.name,
      email: user.email,
      age: user.age
    }

    changes = calculate_changes(old_data, new_data)

    { success: true, changes: changes }
  end

  def calculate_changes(old_data, new_data)
    changes_list = []

    old_data.each do |key, old_value|
      new_value = new_data[key]

      if old_value != new_value
        change_entry = {
          field: key,
          old_value: old_value,
          new_value: new_value
        }
        changes_list << change_entry
      end
    end

    changes_list
  end

  def search_users(query)
    search_term = query.downcase.strip
    matching_users = []
    all_users = @repository.list_all_users

    all_users.each do |user_info|
      user_name = user_info[:name].downcase
      user_email = user_info[:email].downcase

      name_matches = user_name.include?(search_term)
      email_matches = user_email.include?(search_term)

      if name_matches || email_matches
        match_score = calculate_match_score(search_term, user_name, user_email)
        user_with_score = user_info.merge(score: match_score)
        matching_users << user_with_score
      end
    end

    sorted_results = matching_users.sort_by { |u| -u[:score] }
    sorted_results
  end

  def calculate_match_score(term, name, email)
    score = 0
    term_length = term.length

    if name == term
      exact_match_bonus = 100
      score += exact_match_bonus
    elsif name.start_with?(term)
      prefix_bonus = 50
      score += prefix_bonus
    elsif name.include?(term)
      substring_bonus = 25
      score += substring_bonus
    end

    if email.start_with?(term)
      email_prefix_bonus = 30
      score += email_prefix_bonus
    elsif email.include?(term)
      email_substring_bonus = 15
      score += email_substring_bonus
    end

    length_factor = term_length * 2
    score += length_factor

    score
  end

  def bulk_import_users(user_data_list)
    imported_count = 0
    failed_count = 0
    errors = []

    user_data_list.each_with_index do |user_data, index|
      begin
        name = user_data[:name]
        email = user_data[:email]
        age = user_data[:age]

        result = register_user(name, email, age)

        if result[:error]
          failed_count += 1
          error_entry = {
            index: index,
            data: user_data,
            error: result[:error]
          }
          errors << error_entry
        else
          imported_count += 1
        end
      rescue => e
        failed_count += 1
        exception_error = {
          index: index,
          data: user_data,
          error: e.message
        }
        errors << exception_error
      end
    end

    total_processed = imported_count + failed_count
    success_rate = (imported_count.to_f / total_processed * 100).round(2)

    import_result = {
      total: total_processed,
      imported: imported_count,
      failed: failed_count,
      success_rate: success_rate,
      errors: errors
    }

    import_result
  end
end

module StringHelpers
  def self.truncate(text, length)
    text_string = text.to_s
    max_length = length.to_i

    if text_string.length <= max_length
      return text_string
    end

    truncated = text_string[0...max_length]
    suffix = "..."
    result = truncated + suffix
    result
  end

  def self.slugify(text)
    lowercase_text = text.downcase
    spaces_to_dashes = lowercase_text.gsub(/\s+/, '-')
    only_alphanumeric = spaces_to_dashes.gsub(/[^a-z0-9\-]/, '')
    no_multiple_dashes = only_alphanumeric.gsub(/-+/, '-')
    no_leading_trailing = no_multiple_dashes.gsub(/^-|-$/, '')
    no_leading_trailing
  end

  def self.capitalize_words(text)
    words = text.split(' ')
    capitalized_words = []

    words.each do |word|
      first_char = word[0].upcase
      rest_chars = word[1..-1].downcase
      capitalized_word = first_char + rest_chars
      capitalized_words << capitalized_word
    end

    result = capitalized_words.join(' ')
    result
  end
end

class ReportGenerator
  def initialize
    @reports = []
    generator_id = SecureRandom.uuid
    created_at = Time.now
  end

  def generate_user_report(users)
    report_id = "report-#{Time.now.to_i}"
    report_data = []

    total_users = users.count
    total_age = 0

    users.each do |user|
      user_age = user.age || 0
      total_age += user_age

      user_entry = {
        name: user.name,
        email: user.email,
        age: user_age
      }
      report_data << user_entry
    end

    average_age = total_users > 0 ? (total_age.to_f / total_users).round(2) : 0

    age_groups = categorize_by_age(users)

    report = {
      id: report_id,
      generated_at: Time.now,
      total_users: total_users,
      average_age: average_age,
      age_groups: age_groups,
      data: report_data
    }

    @reports << report
    report
  end

  def categorize_by_age(users)
    youth = []
    adults = []
    seniors = []

    users.each do |user|
      user_age = user.age || 0

      if user_age < 18
        youth << user
      elsif user_age < 65
        adults << user
      else
        seniors << user
      end
    end

    categories = {
      youth: youth.count,
      adults: adults.count,
      seniors: seniors.count
    }

    categories
  end

  def export_report(report_id, format)
    target_report = nil

    @reports.each do |report|
      current_id = report[:id]
      if current_id == report_id
        target_report = report
        break
      end
    end

    unless target_report
      error_msg = "Report not found: #{report_id}"
      return { error: error_msg }
    end

    case format
    when 'json'
      json_output = target_report.to_json
      json_output
    when 'csv'
      csv_lines = []
      header = "Name,Email,Age"
      csv_lines << header

      target_report[:data].each do |entry|
        line = "#{entry[:name]},#{entry[:email]},#{entry[:age]}"
        csv_lines << line
      end

      csv_output = csv_lines.join("\n")
      csv_output
    else
      unsupported_format = "Unsupported format: #{format}"
      { error: unsupported_format }
    end
  end
end
