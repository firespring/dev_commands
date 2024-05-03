require 'spec_helper'
require 'lib/firespring_dev_commands/git'

describe Dev::Git do
  let(:main_branch) { random }
  let(:staging_branch) { random }
  let(:repo_name) { random }
  let(:repo_dir) { random }
  let(:info) { Dev::Git::Info.new(repo_name, repo_dir) }

  let(:instance) do
    described_class.new(
      main_branch:,
      staging_branch:,
      info:
    )
  end

  describe '.initialize' do
    subject { instance }

    before do
      expect_any_instance_of(described_class).to receive(:check_version)
    end

    it 'checks version' do
      instance
    end
  end
end
