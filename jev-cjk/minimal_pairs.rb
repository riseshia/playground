require "fileutils"
require "json"
require "yaml"
require_relative "jev"

CASES_PATH = File.join(__dir__, "minimal_pairs.yml")
RESULTS_PATH = File.join(__dir__, "results", "minimal_pairs.json")

Outcome = Data.define(:phenomenon, :question, :text_language, :question_language, :holds, :fails) do
  def passed? = holds > 0.5 && fails < 0.5
  def gap = holds - fails
end

def question_languages_for(text_language)
  ["en", text_language].uniq
end

def ask_both_questions(jev, kase, text_language, text)
  questions = question_languages_for(text_language).to_h do |question_language|
    [question_language, Jev.noul(kase.fetch("question").fetch(question_language))]
  end
  jev.ask(state: text, questions:).answers.transform_values { |answer| answer.fetch("noul") }
end

def run(jev, cases)
  cases.flat_map do |kase|
    kase.fetch("texts").flat_map do |text_language, texts|
      holds = ask_both_questions(jev, kase, text_language, texts.fetch("holds"))
      fails = ask_both_questions(jev, kase, text_language, texts.fetch("fails"))

      question_languages_for(text_language).map do |question_language|
        Outcome.new(
          phenomenon: kase.fetch("phenomenon"),
          question: kase.fetch("question").fetch("en"),
          text_language:,
          question_language:,
          holds: holds.fetch(question_language),
          fails: fails.fetch(question_language)
        )
      end
    end
  end
end

def print_summary(outcomes)
  puts format("%-18s %-5s %-5s %7s %9s", "phenomenon", "text", "asked", "passed", "mean gap")
  outcomes.group_by { |o| [o.phenomenon, o.text_language, o.question_language] }.each do |(phenomenon, text, asked), group|
    mean_gap = group.sum(&:gap) / group.size
    puts format("%-18s %-5s %-5s %4d/%-2d %9.2f", phenomenon, text, asked, group.count(&:passed?), group.size, mean_gap)
  end
end

def print_failures(outcomes)
  puts "\nfailed pairs (holds should be > 0.5, fails < 0.5)"
  outcomes.reject(&:passed?).each do |o|
    puts format("  %-18s text=%s asked=%s holds=%.2f fails=%.2f  %s", o.phenomenon, o.text_language, o.question_language, o.holds, o.fails, o.question)
  end
end

outcomes = run(Jev.from_dotenv, YAML.load_file(CASES_PATH))

FileUtils.mkdir_p(File.dirname(RESULTS_PATH))
File.write(RESULTS_PATH, JSON.pretty_generate(outcomes.map(&:to_h)))

print_summary(outcomes)
print_failures(outcomes)
