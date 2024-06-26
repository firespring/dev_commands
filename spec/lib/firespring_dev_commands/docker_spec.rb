require 'spec_helper'
require 'lib/firespring_dev_commands/docker'

describe Dev::Docker do
  let(:instance) { described_class.new }

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
