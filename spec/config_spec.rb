require 'helper'

RSpec.describe ProbeDockRSpec do
  let(:config_double){ double load!: nil }
  let(:rspec_config_double){ double add_formatter: nil }
  subject{ described_class }

  before :each do
    allow(::RSpec).to receive(:configure).and_yield(rspec_config_double)
    allow(ProbeDockProbe).to receive(:config).and_return(config_double)
    ProbeDockRSpec.instance_variable_set '@setup', nil
  end

  describe ".configure" do

    it "should load and return the configuration" do
      expect(config_double).to receive(:load!).with(no_args)
      expect(ProbeDockRSpec.configure).to be(config_double)
    end

    it "should pass the given block to the configuration's load method" do
      b = lambda{}
      received_block = nil
      expect(config_double).to receive(:load!).with(no_args){ |*args,&block| received_block = block }
      ProbeDockRSpec.configure &b
      expect(received_block).to be(b)
    end

    it "should add the formatter to RSpec" do
      expect(rspec_config_double).to receive(:add_formatter).with(ProbeDockRSpec::Formatter)
      subject.configure
    end

    it "should only add the RSpec formatter once" do
      expect(rspec_config_double).to receive(:add_formatter).once
      3.times{ subject.configure }
    end

    it "should not add the RSpec formatter with the :setup option set to false" do
      expect(rspec_config_double).not_to receive(:add_formatter)
      subject.configure setup: false
    end
  end
end
