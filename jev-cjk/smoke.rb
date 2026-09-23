require_relative "jev"

STATES = {
  en: "Nintendo has announced a new The Legend of Zelda title. The release is scheduled for December 18, and pre-orders open next Friday.",
  ja: "任天堂が『ゼルダの伝説』の新作を発表しました。発売日は12月18日で、予約受付は来週の金曜日から始まります。",
  ko: "닌텐도가 젤다의 전설 신작을 발표했습니다. 발매일은 12월 18일이고, 예약은 다음 주 금요일부터 시작합니다."
}.freeze

QUESTIONS = {
  about_games: Jev.noul("Is this text about video games?"),
  about_programming: Jev.noul("Is this text about software development or programming?"),
  has_deadline: Jev.noul("Does this text mention a specific date the reader may want to act on?"),
  kind: Jev.choice(
    "What kind of text is this?",
    criteria: {
      factual: "Reports facts or announcements",
      opinion: "Argues a viewpoint or gives analysis",
      actionable: "Its main value is a date or deadline the reader should act on"
    }
  ),
  interest: Jev.score(
    "How relevant is this to someone who follows console game releases?",
    criteria: ["Unrelated", "Loosely related", "Directly about a console game release"]
  )
}.freeze

jev = Jev.from_dotenv

STATES.each do |language, state|
  result = jev.ask(state:, questions: QUESTIONS)
  puts "== #{language}  #{(result.elapsed * 1000).round}ms  #{result.usage}"
  result.answers.each { |id, answer| puts "  #{id}: #{answer.except("type", "legend")}" }
end
