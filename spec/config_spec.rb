require 'helper'
require 'fileutils'

describe ProbeDockRSpec::Config do
  include Capture::Helpers
  include FakeFS::SpecHelpers
  Server ||= ProbeDockRSpec::Server
  Project ||= ProbeDockRSpec::Project

  let(:config){ ProbeDockRSpec::Config.new }
  let(:rspec_config){ double add_formatter: nil }
  let(:project_double){ double update: nil }
  let(:server_doubles){ [] }
  subject{ config }

  before :each do
    allow(Project).to receive(:new).and_return(project_double)
    allow(Server).to receive(:new){ |options| server_double(options).tap{ |d| server_doubles << d } }
  end

  describe ".config" do
    let(:new_config){ double load: nil }
    before(:each){ allow(ProbeDockRSpec::Config).to receive(:new).and_return(new_config) }

    it "should create, load and memoize a configuration" do
      expect(new_config).to receive(:load!).once
      3.times{ expect(ProbeDockRSpec.config).to be(new_config) }
    end
  end

  describe ".configure" do
    let(:load_warnings){ [] }
    let(:config){ double load!: nil, check!: nil, setup!: nil, load_warnings: load_warnings }
    before(:each){ allow(ProbeDockRSpec).to receive(:config).and_return(config) }

    it "should yield and return the configuration" do
      result = nil
      expect{ |b| result = ProbeDockRSpec.configure &b }.to yield_with_args(config)
      expect(result).to be(config)
    end

    it "should set up the configuration" do
      expect(config).to receive(:setup!)
      ProbeDockRSpec.configure
    end

    it "should not set up if disabled" do
      expect(config).not_to receive(:setup!)
      ProbeDockRSpec.configure setup: false
    end

    describe "with load warnings" do
      let(:load_warnings){ [ 'a', 'b' ] }

      it "should print load warnings" do
        c = capture{ ProbeDockRSpec.configure }
        expect(c.stdout).to be_empty
        expect(c.stderr).to match('Probe Dock - a')
        expect(c.stderr).to match('Probe Dock - b')
      end
    end
  end

  describe "when created" do
    subject{ ProbeDockRSpec::Config }

    it "should create a project" do
      expect(Project).to receive(:new)
      subject.new
    end
  end

  before :each do
    allow(RSpec).to receive(:configure).and_yield(rspec_config)
    @probe_dock_env_vars = ENV.select{ |k,v| k.match /\APROBE_DOCK_/ }.each_key{ |k| ENV.delete k }
  end

  after :each do
    @probe_dock_env_vars.each_pair{ |k,v| ENV[k] = v }
  end

  describe "default attributes" do
    its(:publish?){ should be(false) }
    its(:local_mode?){ should be(false) }
    its(:project){ should be(project_double) }
    its(:cache_payload?){ should be(false) }
    its(:print_payload?){ should be(false) }
    its(:save_payload?){ should be(false) }
    its(:servers){ should be_empty }
    its(:server){ should have_server_configuration(name: nil) }
    its(:workspace){ should be_nil }
  end

  it "should expand the workspace" do
    subject.workspace = 'foo'
    expect(subject.workspace).to eq(File.expand_path('foo'))
  end

  it "should add the formatter to RSpec" do
    expect(rspec_config).to receive(:add_formatter).with(ProbeDockRSpec::Formatter)
    subject.setup!
  end

  describe "when loaded" do
    let(:home_config){ nil }
    let(:home_config_path){ File.expand_path('~/.probe-dock/config.yml') }
    let(:working_config){ nil }
    let(:working_config_path){ '/project/probe-dock.yml' }
    let(:loaded_config){ config.tap(&:load!).tap(&:check!) }

    before :each do
      FileUtils.mkdir_p '/project'
      FileUtils.mkdir_p File.dirname(home_config_path)
      FileUtils.mkdir_p File.dirname(working_config_path)
      File.open(home_config_path, 'w'){ |f| f.write home_config.strip } if home_config
      File.open(working_config_path, 'w'){ |f| f.write working_config.strip } if working_config
      Dir.chdir '/project'
    end

    describe "with full information in the home config" do
      let(:home_config){ %|
servers:
  a:
    apiUrl: "http://example.com/api"
    apiToken: "abcdefghijklmnopqrstuvwxyz"
    projectApiId: "9876543210"
  b:
    apiUrl: "http://subdomain.example.com/api"
    apiToken: "bcdefghijklmnopqrstuvwxyza"
project:
  version: 1.2.3
  apiId: "0123456789"
  category: A category
  tags: [ a, b ]
  tickets: [ c, d ]
publish: true
local: true
server: a
workspace: /old
payload:
  cache: false
  print: true
  save: false
      | }

      it "should have no load warnings" do
        expect(loaded_config.load_warnings).to be_empty
      end

      it "should create a project" do
        expect(project_double).to receive(:update).with({
          version: '1.2.3',
          api_id: '9876543210',
          category: 'A category',
          tags: [ 'a', 'b' ],
          tickets: [ 'c', 'd' ]
        })
        config.load!
        expect(config.project).to be(project_double)
      end

      it "should set the publishing attributes" do
        expect(attrs_hash(loaded_config, :publish?, :local_mode?)).to eq({
          publish?: true,
          local_mode?: true
        });
      end

      it "should set the workspace attributes" do
        expect(attrs_hash(loaded_config, :workspace, :cache_payload?, :print_payload?, :save_payload?)).to eq({
          workspace: '/old',
          cache_payload?: false,
          print_payload?: true,
          save_payload?: false
        })
      end

      it "should return client options" do
        expect(loaded_config.client_options).to eq({
          publish: true,
          local_mode: true,
          workspace: '/old',
          cache_payload: false,
          print_payload: true,
          save_payload: false
        })
      end

      it "should create two servers" do
        expect(Server).to receive(:new).with({
          name: 'a',
          api_url: 'http://example.com/api',
          api_token: 'abcdefghijklmnopqrstuvwxyz',
          project_api_id: '9876543210'
        }).ordered
        expect(Server).to receive(:new).with({
          name: 'b',
          api_url: 'http://subdomain.example.com/api',
          api_token: 'bcdefghijklmnopqrstuvwxyza',
          project_api_id: '0123456789'
        })
        config.load!
        expect(config.servers).to eq(server_doubles.last(2))
      end

      it "should select the specified server" do
        expect(loaded_config.server).to eq(loaded_config.servers[0])
      end

      shared_examples_for "an overriden config" do

        it "should have no load warnings" do
          expect(loaded_config.load_warnings).to be_empty
        end

        it "should override project attributes" do
          expect(project_double).to receive(:update).with({
            version: '2.3.4',
            api_id: '9876543210',
            category: 'Another category',
            tags: 'oneTag',
            tickets: [ 'c', 'd' ]
          })
          config.load!
          expect(config.project).to be(project_double)
        end

        it "should override the publishing attributes" do
          expect(attrs_hash(loaded_config, :publish?, :local_mode?)).to eq({
            publish?: true,
            local_mode?: false
          });
        end

        it "should set the workspace attributes" do
          expect(attrs_hash(loaded_config, :workspace, :cache_payload?, :print_payload?, :save_payload?)).to eq({
            workspace: '/tmp',
            cache_payload?: true,
            print_payload?: false,
            save_payload?: true
          })
        end

        it "should override client options" do
          expect(loaded_config.client_options).to eq({
            publish: true,
            local_mode: false,
            workspace: '/tmp',
            cache_payload: true,
            print_payload: false,
            save_payload: true
          })
        end

        it "should create two servers" do
          expect(Server).to receive(:new).with({
            name: 'a',
            api_url: 'http://example.com/api',
            api_token: 'abcdefghijklmnopqrstuvwxyz',
            project_api_id: '9876543210'
          }).ordered
          expect(Server).to receive(:new).with({
            name: 'b',
            api_url: 'http://other-subdomain.example.com/api',
            api_token: 'cdefghijklmnopqrstuvwxyzab',
            project_api_id: '0000000000'
          })
          config.load!
          expect(config.servers).to eq(server_doubles.last(2))
        end

        it "should select the specified server" do
          expect(loaded_config.server).to eq(loaded_config.servers[0])
        end

        describe "with overriding environment variables" do
          let :probe_dock_env_vars do
            {
              publish: '0',
              local: '1',
              server: 'b',
              workspace: '/opt',
              cache_payload: '0',
              print_payload: '1'
            }
          end
          before(:each){ probe_dock_env_vars.each_pair{ |k,v| ENV["PROBE_DOCK_#{k.upcase}"] = v } }

          it "should have no load warnings" do
            expect(subject.load_warnings).to be_empty
          end

          it "should override the publishing attributes" do
            expect(attrs_hash(loaded_config, :publish?, :local_mode?)).to eq({
              publish?: false,
              local_mode?: true
            });
          end

          it "should set the workspace attributes" do
            expect(attrs_hash(loaded_config, :workspace, :cache_payload?, :print_payload?, :save_payload?)).to eq({
              workspace: '/opt',
              cache_payload?: false,
              print_payload?: true,
              save_payload?: true
            })
          end

          it "should select the specified server" do
            expect(loaded_config.server).to eq(loaded_config.servers[1])
          end
        end
      end

      describe "with an overriding working directory config" do
        let(:working_config){ %|
servers:
  b:
    apiUrl: "http://other-subdomain.example.com/api"
    apiToken: "cdefghijklmnopqrstuvwxyzab"
project:
  version: 2.3.4
  apiId: "0000000000"
  category: Another category
  tags: oneTag
payload:
  cache: true
  print: false
  save: true
publish: true
local: false
workspace: /tmp
        | }

        it_should_behave_like "an overriden config"

        describe "with $PROBE_DOCK_CONFIG overriding the working file path" do
          let(:working_config_path){ '/tmp/foo/probe-dock.yml' }
          before(:each){ ENV['PROBE_DOCK_CONFIG'] = '/tmp/foo/probe-dock.yml' }
          it_should_behave_like "an overriden config"
        end
      end
    end

    describe "load warnings" do
      subject{ loaded_config }

      describe "with no config files" do
        its(:server){ should have_server_configuration(name: nil) }
        its(:publish?){ should be(false) }
        its(:load_warnings){ should have(2).items }
        it("should warn that no config file was found"){ should have_elements_matching(:load_warnings, /no config file found/i, home_config_path, working_config_path, /no server defined/i) }
      end

      describe "with no server" do
        let(:working_config){ "publish: true" }
        its(:server){ should have_server_configuration(name: nil) }
        its(:publish?){ should be(true) }
        its(:load_warnings){ should have(1).items }
        it{ should have_elements_matching(:load_warnings, /no server defined/i) }
      end

      describe "with no server selected" do
        let(:working_config){ %|
servers:
  a:
    apiUrl: http://example.com/api
publish: true
        | }
        its(:server){ should have_server_configuration(name: nil) }
        its(:publish?){ should be(true) }
        its(:load_warnings){ should have(1).items }
        it{ should have_elements_matching(:load_warnings, /no server name given/i) }
      end

      describe "with an unknown server selected" do
        let(:working_config){ %|
servers:
  a:
    apiUrl: http://example.com/api
publish: true
server: unknown
        | }
        its(:server){ should have_server_configuration(name: nil) }
        its(:publish?){ should be(true) }
        its(:load_warnings){ should be_empty }
      end
    end
  end

  def server_double options = {}
    options ||= {}

    double_options = %i(name api_url api_token project_api_id).inject({}){ |memo,k| memo[k] = options[k] ? options[k].to_s : nil; memo }
    double_options[:clear] = nil
    double_options[:name=] = nil

    double double_options
  end

  def attrs_hash source, *attrs
    attrs.inject({}){ |memo,a| memo[a.to_sym] = source.send(a); memo }
  end
end
