# frozen_string_literal: true

require_relative '../run'
require 'tempfile'
require 'fileutils'

RSpec.describe ActionConverter do
  let(:sample_workflow) do
    <<~YAML
      name: Sample Workflow
      on:
        push:
          branches: [ main ]
      
      jobs:
        test:
          runs-on: ubuntu-latest
          steps:
            - uses: actions/checkout@v3
            - uses: actions/setup-node@v4
            - uses: ruby/setup-ruby@v1
            - uses: already/using-sha@1234567890123456789012345678901234567890
    YAML
  end

  let(:workflow_file) do
    file = Tempfile.new(['workflow', '.yml'])
    file.write(sample_workflow)
    file.close
    file.path
  end

  after do
    File.unlink(workflow_file) if File.exist?(workflow_file)
  end

  describe '#convert_to_sha!' do
    let(:converter) { described_class.new(workflow_file) }
    
    before do
      # gh apiコマンドの呼び出しをモック化
      allow(converter).to receive(:get_sha_from_tag).with('actions/checkout', 'v3').and_return('abcdef1234567890abcdef1234567890abcdef12')
      allow(converter).to receive(:get_sha_from_tag).with('actions/setup-node', 'v4').and_return('fedcba0987654321fedcba0987654321fedcba09')
      allow(converter).to receive(:get_sha_from_tag).with('ruby/setup-ruby', 'v1').and_return('1a2b3c4d5e6f7g8h9i0j1a2b3c4d5e6f7g8h9i0j')
      # すでにSHA参照の場合はスキップされるはず
      allow(converter).to receive(:get_sha_from_tag).with('already/using-sha', '1234567890123456789012345678901234567890').and_return('1234567890123456789012345678901234567890')
    end

    it 'converts tag references to SHA references' do
      modified_content = converter.convert_to_sha!
      
      # 各アクションの参照がSHAに変換されていることを確認
      expect(modified_content).to include('uses: actions/checkout@abcdef1234567890abcdef1234567890abcdef12 # v3')
      expect(modified_content).to include('uses: actions/setup-node@fedcba0987654321fedcba0987654321fedcba09 # v4')
      expect(modified_content).to include('uses: ruby/setup-ruby@1a2b3c4d5e6f7g8h9i0j1a2b3c4d5e6f7g8h9i0j # v1')
      # すでにSHA参照のものは変更されないことを確認
      expect(modified_content).to include('uses: already/using-sha@1234567890123456789012345678901234567890')
      # コメントが追加されていないことを確認
      expect(modified_content).not_to include('uses: already/using-sha@1234567890123456789012345678901234567890 # 1234567890123456789012345678901234567890')
    end

    it 'preserves the original tag as a comment' do
      modified_content = converter.convert_to_sha!
      
      expect(modified_content).to include('# v3')
      expect(modified_content).to include('# v4')
      expect(modified_content).to include('# v1')
    end

    it 'skips already SHA references' do
      # すでにSHA形式のものは変更されないことを確認
      modified_content = converter.convert_to_sha!
      
      # 元のSHA参照がそのまま含まれていることを確認
      expect(modified_content).to include('uses: already/using-sha@1234567890123456789012345678901234567890')
      
      # コメントが追加されていないことを確認
      expect(modified_content).not_to include('uses: already/using-sha@1234567890123456789012345678901234567890 # 1234567890123456789012345678901234567890')
    end
  end

  describe '#get_sha_from_tag' do
    let(:converter) { described_class.new(workflow_file) }

    it 'returns nil for invalid repository format' do
      result = converter.get_sha_from_tag('invalid-repo-format', 'v1')
      expect(result).to be_nil
    end

    context 'when gh api command returns valid response' do
      let(:tag_response) do
        <<~JSON
        {
          "object": {
            "type": "commit",
            "sha": "commit-sha-value"
          }
        }
        JSON
      end

      let(:tag_object_response) do
        <<~JSON
        {
          "object": {
            "type": "tag",
            "url": "https://api.github.com/repos/owner/repo/git/tags/tag-object-sha"
          }
        }
        JSON
      end

      let(:tag_object_details_response) do
        <<~JSON
        {
          "object": {
            "sha": "tag-object-commit-sha"
          }
        }
        JSON
      end
      
      it 'returns SHA for commit type tag' do
        # Open3.capture3をモック化
        allow(Open3).to receive(:capture3).with("gh", "api", "repos/owner/repo/git/refs/tags/v1").and_return([tag_response, "", double(success?: true)])
        
        result = converter.get_sha_from_tag('owner/repo', 'v1')
        expect(result).to eq('commit-sha-value')
      end

      it 'returns SHA for tag object type tag' do
        # タグリファレンスとタグオブジェクトの両方のAPIコールをモック化
        allow(Open3).to receive(:capture3).with("gh", "api", "repos/owner/repo/git/refs/tags/v1").and_return([tag_object_response, "", double(success?: true)])
        allow(Open3).to receive(:capture3).with("gh", "api", "https://api.github.com/repos/owner/repo/git/tags/tag-object-sha").and_return([tag_object_details_response, "", double(success?: true)])
        
        result = converter.get_sha_from_tag('owner/repo', 'v1')
        expect(result).to eq('tag-object-commit-sha')
      end

      it 'returns nil when gh command fails' do
        allow(Open3).to receive(:capture3).with("gh", "api", "repos/owner/repo/git/refs/tags/v1").and_return(["", "Error: Not Found", double(success?: false)])
        
        result = converter.get_sha_from_tag('owner/repo', 'v1')
        expect(result).to be_nil
      end
    end
  end
end
