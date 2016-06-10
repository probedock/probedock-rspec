require 'helper'

RSpec.describe ProbeDockRSpec do
  let(:config_double){ double }
  subject{ described_class }

  before :each do
    ProbeDockRSpec.instance_variable_set '@setup', nil
    ProbeDockRSpec.instance_variable_set '@config', nil
    allow(ProbeDockProbe::Config).to receive(:new).and_return(config_double)
  end

  describe ".config" do
    it "should create a probe configuration once" do
      expect(ProbeDockProbe::Config).to receive(:new).with(no_args).once
      3.times{ expect(subject.config).to eq(config_double) }
    end

    it "should allow overriding the probe configuration" do
      expect(ProbeDockProbe::Config).not_to receive(:new)
      subject.config = config_double
      expect(subject.config).to eq(config_double)
    end

    it "should allow overriding the probe configuration after it has been created" do
      expect(ProbeDockProbe::Config).to receive(:new).with(no_args).once
      expect(subject.config).to eq(config_double)

      new_config = double
      subject.config = new_config
      expect(subject.config).to eq(new_config)
    end
  end

  describe ".configure" do
    let(:project_double){ double :category => nil, :'category=' => nil }
    let(:config_double){ double load!: nil, project: project_double }
    let(:rspec_config_double){ double add_formatter: nil }

    before :each do
      allow(::RSpec).to receive(:configure).and_yield(rspec_config_double)
    end

    it "should load and return the configuration" do
      expect(project_double).to receive(:category=).with('RSpec')
      expect(config_double).to receive(:load!).with(no_args)
      expect(ProbeDockRSpec.configure).to be(config_double)
    end

    it "should pass the given block to the configuration's load method" do

      b = lambda{}
      received_block = nil

      expect(project_double).to receive(:category=).with('RSpec')
      expect(config_double).to receive(:load!).with(no_args){ |*args,&block| received_block = block }
      ProbeDockRSpec.configure &b

      expect(received_block).to be(b)
    end

    it "should add the formatter to RSpec once" do
      expect(rspec_config_double).to receive(:add_formatter).with(ProbeDockRSpec::Formatter)
      3.times{ subject.configure }
    end

    it "should not add the RSpec formatter with the :setup option set to false" do
      expect(rspec_config_double).not_to receive(:add_formatter)
      subject.configure setup: false
    end
  end
end
