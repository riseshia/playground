require "fileutils"
require "json"
require_relative "hf_dataset"
require_relative "jev"

# MIRACL reranking: questions written by native speakers, each with 100 Wikipedia passages marked relevant or not.
# The shape of "rerank the keyword-search hits for a note search": one yes/no question per query-passage pair.
DATASET = "mteb/MIRACLReranking"
LANGUAGES = ["en", "ja", "ko"].freeze
QUERY_COUNT = 30
# The corpus and qrels list exactly this many passages per query, in query order,
# so the first QUERY_COUNT queries are covered by the first QUERY_COUNT * 100 rows.
PASSAGES_PER_QUERY = 100
# Every relevant passage is kept and the pool is filled up with irrelevant ones.
POOL_SIZE = 25
RESULTS_PATH = File.join(__dir__, "results", "miracl.json")

def question_for(query)
  Jev.noul({question: "Does this passage contain the answer to the search query?", query:})
end

def load_pools(language)
  row_limit = QUERY_COUNT * PASSAGES_PER_QUERY
  queries = HfDataset.load_rows(dataset: DATASET, config: "#{language}-queries", split: "dev", limit: QUERY_COUNT)
  passages = HfDataset.load_rows(dataset: DATASET, config: "#{language}-corpus", split: "dev", limit: row_limit).to_h { |row| [row.fetch("_id"), row] }
  relevance = HfDataset.load_rows(dataset: DATASET, config: "#{language}-qrels", split: "dev", limit: row_limit).group_by { |row| row.fetch("query-id") }

  queries.map do |query|
    relevant, irrelevant = relevance.fetch(query.fetch("_id")).partition { |row| row.fetch("score").positive? }
    pool = (relevant + irrelevant).first([POOL_SIZE, relevant.size + 1].max)
    {query: query.fetch("text"), candidates: pool.map { |row| {passage: passages.fetch(row.fetch("corpus-id")), relevant: row.fetch("score").positive?} }}
  end
end

def rerank(jev, pool)
  question = question_for(pool.fetch(:query))
  pool.fetch(:candidates).map do |candidate|
    passage = candidate.fetch(:passage)
    noul = jev.ask(state: {title: passage.fetch("title"), text: passage.fetch("text")}, questions: {answers: question}).answers.fetch("answers").fetch("noul")
    {relevant: candidate.fetch(:relevant), noul:}
  end
end

judged_by_language = LANGUAGES.map do |language|
  Thread.new do
    jev = Jev.from_dotenv
    [language, load_pools(language).map { |pool| rerank(jev, pool) }]
  end
end.to_h(&:value)

FileUtils.mkdir_p(File.dirname(RESULTS_PATH))
File.write(RESULTS_PATH, JSON.generate(judged_by_language))

puts "wrote #{judged_by_language.values.sum(&:size)} reranked queries to #{RESULTS_PATH}"
