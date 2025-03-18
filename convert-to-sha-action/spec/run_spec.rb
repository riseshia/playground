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
            - uses: actions-rust-lang/setup-rust-toolchain@v1.11
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
      # モック: タグからSHAとフルバージョンを取得
      allow(converter).to receive(:get_sha_and_full_version).with('actions/checkout', 'v3').and_return(['abcdef1234567890abcdef1234567890abcdef12', 'v3.5.0'])
      allow(converter).to receive(:get_sha_and_full_version).with('actions/setup-node', 'v4').and_return(['fedcba0987654321fedcba0987654321fedcba09', 'v4.2.2'])
      allow(converter).to receive(:get_sha_and_full_version).with('ruby/setup-ruby', 'v1').and_return(['1a2b3c4d5e6f7g8h9i0j1a2b3c4d5e6f7g8h9i0j', 'v1.101.0'])
      allow(converter).to receive(:get_sha_and_full_version).with('actions-rust-lang/setup-rust-toolchain', 'v1.11').and_return(['rust123456789012345678901234567890abcdef12', 'v1.11.0'])
      # すでにSHA参照の場合はスキップされる
      allow(converter).to receive(:get_sha_from_tag).with('already/using-sha', '1234567890123456789012345678901234567890').and_return('1234567890123456789012345678901234567890')
    end

    it 'converts tag references to SHA references with full version in comments' do
      modified_content = converter.convert_to_sha!
      
      # 各アクションの参照がSHAに変換され、詳細なバージョン情報がコメントに含まれていることを確認
      expect(modified_content).to include('uses: actions/checkout@abcdef1234567890abcdef1234567890abcdef12 # v3.5.0')
      expect(modified_content).to include('uses: actions/setup-node@fedcba0987654321fedcba0987654321fedcba09 # v4.2.2')
      expect(modified_content).to include('uses: ruby/setup-ruby@1a2b3c4d5e6f7g8h9i0j1a2b3c4d5e6f7g8h9i0j # v1.101.0')
      expect(modified_content).to include('uses: actions-rust-lang/setup-rust-toolchain@rust123456789012345678901234567890abcdef12 # v1.11.0')
      # すでにSHA参照のものは変更されないことを確認
      expect(modified_content).to include('uses: already/using-sha@1234567890123456789012345678901234567890')
      # コメントが追加されていないことを確認
      expect(modified_content).not_to include('uses: already/using-sha@1234567890123456789012345678901234567890 # 1234567890123456789012345678901234567890')
    end

    it 'preserves the original tag as a comment when full version is not available but ensures semantic versioning format' do
      # フルバージョンが取得できない場合のテスト
      allow(converter).to receive(:get_sha_and_full_version).with('actions/checkout', 'v3').and_return(['abcdef1234567890abcdef1234567890abcdef12', 'v3.0.0'])
      
      modified_content = converter.convert_to_sha!
      
      # フルバージョンが取得できない場合は元のタグが完全なセマンティックバージョン形式でコメントに含まれることを確認
      expect(modified_content).to include('uses: actions/checkout@abcdef1234567890abcdef1234567890abcdef12 # v3.0.0')
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

  describe '#get_sha_and_full_version' do
    let(:converter) { described_class.new(workflow_file) }

    it 'returns SHA and full version for major version tag' do
      # タグからSHAを取得する処理のモック
      allow(converter).to receive(:get_sha_from_tag).with('actions/checkout', 'v3').and_return('abcdef1234567890abcdef1234567890abcdef12')
      # 詳細バージョンを取得する処理のモック
      allow(converter).to receive(:find_detailed_version_from_sha).with('actions', 'checkout', 'abcdef1234567890abcdef1234567890abcdef12', 'v3').and_return('v3.5.0')
      
      sha, full_version = converter.get_sha_and_full_version('actions/checkout', 'v3')
      
      expect(sha).to eq('abcdef1234567890abcdef1234567890abcdef12')
      expect(full_version).to eq('v3.5.0')
    end

    it 'returns SHA and semantic version when full version is not available' do
      allow(converter).to receive(:get_sha_from_tag).with('actions/checkout', 'v3').and_return('abcdef1234567890abcdef1234567890abcdef12')
      allow(converter).to receive(:find_detailed_version_from_sha).with('actions', 'checkout', 'abcdef1234567890abcdef1234567890abcdef12', 'v3').and_return(nil)
      
      sha, full_version = converter.get_sha_and_full_version('actions/checkout', 'v3')
      
      expect(sha).to eq('abcdef1234567890abcdef1234567890abcdef12')
      expect(full_version).to eq('v3.0.0')
    end

    it 'returns SHA and semantic version for non-major version tag' do
      allow(converter).to receive(:get_sha_from_tag).with('actions/checkout', 'v3.5').and_return('abcdef1234567890abcdef1234567890abcdef12')
      
      sha, full_version = converter.get_sha_and_full_version('actions/checkout', 'v3.5')
      
      expect(sha).to eq('abcdef1234567890abcdef1234567890abcdef12')
      expect(full_version).to eq('v3.5.0')
    end

    it 'returns nil when SHA is not available' do
      allow(converter).to receive(:get_sha_from_tag).with('actions/checkout', 'v999').and_return(nil)
      
      sha, full_version = converter.get_sha_and_full_version('actions/checkout', 'v999')
      
      expect(sha).to be_nil
      expect(full_version).to be_nil
    end
  end

  describe '#ensure_semantic_version' do
    let(:converter) { described_class.new(workflow_file) }

    it 'adds missing minor and patch versions' do
      expect(converter.ensure_semantic_version('v1')).to eq('v1.0.0')
    end

    it 'adds missing patch version' do
      expect(converter.ensure_semantic_version('v1.2')).to eq('v1.2.0')
    end

    it 'does not modify complete version' do
      expect(converter.ensure_semantic_version('v1.2.3')).to eq('v1.2.3')
    end

    it 'does not modify non-version strings' do
      expect(converter.ensure_semantic_version('non-version')).to eq('non-version')
    end
  end

  describe '#find_detailed_version_from_sha' do
    let(:converter) { described_class.new(workflow_file) }
    let(:tags_response) do
      <<~JSON
      [
        {"name": "v1.0.0", "commit": {"sha": "sha1"}},
        {"name": "v1.1.0", "commit": {"sha": "sha1"}},
        {"name": "v1.1.1", "commit": {"sha": "sha1"}},
        {"name": "v2.0.0", "commit": {"sha": "sha2"}},
        {"name": "v3.0.0", "commit": {"sha": "sha3"}},
        {"name": "v3.1.0", "commit": {"sha": "sha3"}},
        {"name": "v3.5.0", "commit": {"sha": "sha3"}},
        {"name": "v3.5.1", "commit": {"sha": "sha3"}},
        {"name": "v4.0.0", "commit": {"sha": "sha4"}},
        {"name": "v4.2", "commit": {"sha": "sha4"}},
        {"name": "v4.2.2", "commit": {"sha": "sha4"}}
      ]
      JSON
    end

    before do
      allow(Open3).to receive(:capture3).with("gh", "api", "repos/actions/checkout/tags").and_return([tags_response, "", double(success?: true)])
    end

    it 'returns the latest version tag for a given SHA with complete semantic versioning' do
      version = converter.find_detailed_version_from_sha('actions', 'checkout', 'sha3', 'v3')
      expect(version).to eq('v3.5.1')
    end

    it 'returns the latest version tag for another SHA with complete semantic versioning' do
      version = converter.find_detailed_version_from_sha('actions', 'checkout', 'sha4', 'v4')
      expect(version).to eq('v4.2.2')
    end

    it 'handles incomplete version tags and completes them' do
      allow(Open3).to receive(:capture3).with("gh", "api", "repos/actions/incomplete/tags").and_return([
        '[{"name": "v1.1", "commit": {"sha": "sha1"}}, {"name": "v1.1.0", "commit": {"sha": "sha1"}}]',
        "",
        double(success?: true)
      ])
      
      version = converter.find_detailed_version_from_sha('actions', 'incomplete', 'sha1', 'v1')
      expect(version).to eq('v1.1.0')
    end

    it 'returns nil for SHA with no matching version tags' do
      version = converter.find_detailed_version_from_sha('actions', 'checkout', 'non-existent-sha', 'v5')
      expect(version).to be_nil
    end

    it 'handles errors gracefully' do
      allow(Open3).to receive(:capture3).with("gh", "api", "repos/actions/non-existent/tags").and_return(["", "Error: Not Found", double(success?: false)])
      
      version = converter.find_detailed_version_from_sha('actions', 'non-existent', 'sha1', 'v1')
      expect(version).to be_nil
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
