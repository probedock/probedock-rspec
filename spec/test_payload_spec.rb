require 'helper'

describe ProbeDockRSpec::TestPayload do
  TestPayload ||= ProbeDockRSpec::TestPayload

  let(:run_to_h){ { 'foo' => 'bar' } }
  let(:run_double){ double to_h: run_to_h }
  subject{ TestPayload.new run_double }

  describe "#to_h" do
    let(:to_h_options){ {} }
    subject{ super().to_h to_h_options }

    it "should serialize the test run" do
      expect(run_double).to receive(:to_h).with(to_h_options)
      expect(subject).to eq(run_to_h)
    end
  end
end
