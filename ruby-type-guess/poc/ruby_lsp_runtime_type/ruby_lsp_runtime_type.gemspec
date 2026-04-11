Gem::Specification.new do |spec|
  spec.name = "ruby_lsp_runtime_type"
  spec.version = "0.1.0"
  spec.authors = ["Shia"]
  spec.summary = "Ruby LSP addon: runtime eval-based type inference"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.4.0"

  spec.add_dependency "ruby-lsp", "~> 0.26"
end
