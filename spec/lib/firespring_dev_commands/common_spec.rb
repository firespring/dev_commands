require 'spec_helper'
require 'lib/firespring_dev_commands/common'

describe Dev::Common do
  describe '.run_command' do
    subject { described_class.new.run_command(command, stdin:, stdout:, stderr:, env:, capture:) }

    let(:command) { 'ls' }
    let(:pid) { Object.new }
    let(:result) { [nil, Struct.new(:foo).new(:bar)] }
    let(:result) { Object.new }
    let(:exitstatus) { Object.new }
    let(:success) { true }
    let(:stdin) { Object.new }
    let(:stdout) { Object.new }
    let(:stderr) { Object.new }
    let(:env) { Object.new }
    let(:capture) { false }

    before do
      expect(Process).to receive(:spawn).with(env, command, in: stdin, out: stdout, err: stderr).and_return(pid)
      expect(Process).to receive(:wait2).with(pid).and_return([nil, result])
      expect(result).to receive(:exitstatus).and_return(exitstatus).at_least(:once)
      expect(exitstatus).to receive(:zero?).and_return(success)
    end

    context 'when not capturing' do
      let(:capture) { false }

      context 'when command succeeds' do
        let(:success) { true }

        it 'returns no output' do
          expect(subject).to be_nil
        end
      end

      context 'when command fails' do
        let(:success) { false }

        it 'returns no output' do
          expect(LOG).to receive(:error)
          expect { subject }.to raise_error(StandardError)
        end
      end
    end

    context 'when capturing' do
      let(:capture) { true }
      let(:stdoutread) { Struct.new(:readlines).new(lines) }
      let(:lines) { [random, random] }
      let(:stdout) { Object.new }

      before do
        expect(IO).to receive(:pipe).and_return([stdoutread, stdout])
        expect(stdoutread).to receive(:close)
        expect(stdout).to receive(:close)
      end

      context 'when command succeeds' do
        let(:success) { true }

        it 'returns no output' do
          expect(subject).to eq(lines.join)
        end
      end

      context 'when command fails' do
        let(:success) { false }

        it 'returns no output' do
          expect($stdout).to receive(:puts)
          expect(LOG).to receive(:error)
          expect { subject }.to raise_error(StandardError)
        end
      end
    end
  end
end
