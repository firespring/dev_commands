require 'spec_helper'
require 'lib/firespring_dev_commands/docker/compose'

describe Dev::Docker::Compose do
  let(:compose_files) { [random] }
  let(:environment) { random }
  let(:options) { [random] }
  let(:project_dir) { random }
  let(:project_name) { random }
  let(:services) { [random] }
  let(:volumes) { [random] }
  let(:capture) { random }

  let(:instance) do
    described_class.new(
      compose_files:,
      environment:,
      options:,
      project_dir:,
      project_name:,
      services:,
      volumes:,
      capture:
    )
  end

  before do
    allow(described_class).to receive(:version).and_return('2.15.0')
  end

  describe '.initialize' do
    subject { instance }

    it 'sets expected values' do
      expect(subject.options).to eq options
      expect(subject.project_dir).to eq project_dir
    end
  end

  describe '.build' do
    subject { instance.build }

    let(:command) { random }

    it 'executes the command' do
      expect(instance).to receive(:build_command).with('build').and_return(command)
      expect(instance).to receive(:execute_command).with(command)
      subject
    end
  end

  describe '.run' do
    subject { instance.run(*args) }

    let(:command) { random }
    let(:args) { [random, random] }

    it 'executes the command' do
      expect(instance).to receive(:build_command).with('run', *args).and_return(command)
      expect(instance).to receive(:execute_command).with(command)
      subject
    end
  end

  describe '.build_command' do
    subject { instance.send(:build_command, command) }

    let(:command) { [random] }

    it 'sets default values' do
      expect(subject.join(' ')).to include(instance.compose_files.first)
      expect(subject.join(' ')).to include(instance.project_name)
    end

    context 'environment values are arrays' do
      let(:environment) { [[random, random]] }

      it 'sets default values' do
        expect(subject.join(' ')).to include("-e #{environment[0].first}=#{environment[0].last}")
      end
    end

    context 'environment values are strings' do
      let(:environment) { [random] }

      it 'sets default values' do
        expect(subject.join(' ')).to include("-e #{environment[0]}")
      end
    end

    context 'volumes values are arrays' do
      let(:volumes) { [[random, random]] }

      it 'sets default values' do
        expect(subject.join(' ')).to include("-v #{volumes[0].first}:#{volumes[0].last}")
      end
    end

    context 'volumes values are strings' do
      let(:volumes) { [random] }

      it 'sets default values' do
        expect(subject.join(' ')).to include("-v #{volumes[0]}")
      end
    end
  end

  describe '.execute_command' do
    subject { instance.send(:execute_command, command) }

    let(:command) { [random] }

    it 'runs the command' do
      allow(LOG).to receive(:debug)
      expect_any_instance_of(Dev::Common).to receive(:run_command).with(command, capture: instance.capture)
      subject
    end
  end
end
