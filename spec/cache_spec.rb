require 'helper'

describe RoxClient::RSpec::Cache do
  include FakeFS::SpecHelpers
  Cache ||= RoxClient::RSpec::Cache

  TESTS = [
    {
      data: { key: 'abc', name: 'Something should work', category: 'A category', tags: %w(a b c), tickets: %w(t1 t2), passed?: true, duration: 11 },
      hash: '1e1405ad036b940861c61edcfde2953d973976f58bb43c026a7f42f4a21a0ea1'
    },
    {
      data: { key: 'bcd', name: 'Something else should work', category: 'Another category', tags: [], tickets: %w(t3), passed?: false, duration: 22, message: 'Fubar' },
      hash: '1b38629aae6727253570e3c825afe5cd085730c731439fde087195405b6228ba'
    },
    {
      data: { key: 'cde', name: 'Foo', category: nil, tags: [], tickets: [], passed?: true, duration: 33 },
      hash: '2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae', # hash of "foo"
      actual_hash: 'bda9c9c9e59c0fcecbae3c717e8cd28b85a3cb65f088336f58e951f12db25f8c',
      stale: true
    }
  ]

  let(:cache_options){ { workspace: '/tmp', server_name: 'example', project_api_id: '123' } }
  let(:cache_contents){ build_cache_contents TESTS }
  subject{ Cache.new cache_options }

  it "should not know a result" do
    result = double key: 'abc'
    expect(subject.known?(result)).to be(false)
  end

  it "should not have a result marked as stale" do
    result = double key: 'abc'
    expect(subject.stale?(result)).to be(false)
  end

  describe "#load" do

    it "should not load anything if the cache file doesn't exist" do
      subject.load
      result = double key: 'abc'
      expect(subject.known?(result)).to be(false)
      expect(subject.stale?(result)).to be(false)
    end

    it "should raise an error with no workspace" do
      expect{ Cache.new(cache_options.merge(workspace: nil)).load }.to raise_error(Cache::Error, /workspace/i)
    end

    it "should raise an error with no server name" do
      expect{ Cache.new(cache_options.merge(server_name: nil)).load }.to raise_error(Cache::Error, /server name/i)
    end

    it "should raise an error with no project api id" do
      expect{ Cache.new(cache_options.merge(project_api_id: nil)).load }.to raise_error(Cache::Error, /project API identifier/i)
    end

    describe "after loading" do
      before :each do
        FileUtils.mkdir_p File.dirname(cache_file)
        File.open(cache_file, 'w'){ |f| f.write cache_contents }
        subject.load
      end

      it "should know cached test results" do
        TESTS.each{ |d| expect(subject.known?(double(key: d[:data][:key]))).to be(true) }
        %w(def efg ghi).each{ |k| expect(subject.known?(double(key: k))).to be(false) }
      end

      it "should not indicate unchanged tests as stale" do
        TESTS.reject{ |d| d[:stale] }.each{ |d| expect(subject.stale?(double(d[:data]))).to be(false), "Test #{d[:data]} with hash #{d[:hash]} should not be stale" }
      end

      it "should detect stale tests" do
        TESTS.select{ |d| d[:stale] }.each{ |d| expect(subject.stale?(double(d[:data]))).to be(true), "Test #{d[:data]} with hash #{d[:hash]} should be stale" }
      end

      it "should mark a test as stale if the name changes" do
        expect(subject.stale?(double(TESTS[0][:data].merge(name: 'foo')))).to be(true)
        expect(subject.stale?(double(TESTS[1][:data].merge(name: 'foo')))).to be(true)
      end

      it "should mark a test as stale if the category changes" do
        expect(subject.stale?(double(TESTS[0][:data].merge(category: 'foo')))).to be(true)
        expect(subject.stale?(double(TESTS[1][:data].merge(category: nil)))).to be(true)
      end

      it "should mark a test as stale if the tags change" do
        expect(subject.stale?(double(TESTS[0][:data].merge(tags: %w(a b))))).to be(true)
        expect(subject.stale?(double(TESTS[1][:data].merge(tags: %w(d e f g))))).to be(true)
      end

      it "should mark a test as stale if the tickets change" do
        expect(subject.stale?(double(TESTS[0][:data].merge(tickets: %w(t1 t2 t3))))).to be(true)
        expect(subject.stale?(double(TESTS[1][:data].merge(tickets: [])))).to be(true)
      end

      it "should not mark a test as stale if the status changes" do
        expect(subject.stale?(double(TESTS[0][:data].merge(passed?: false)))).to be(false)
        expect(subject.stale?(double(TESTS[1][:data].merge(passed?: true)))).to be(false)
      end

      it "should not mark a test as stale if the duration changes" do
        expect(subject.stale?(double(TESTS[0][:data].merge(duration: 42)))).to be(false)
        expect(subject.stale?(double(TESTS[1][:data].merge(duration: 24)))).to be(false)
      end

      it "should not mark a test as stale if the message changes" do
        expect(subject.stale?(double(TESTS[0][:data].merge(message: 'Broken')))).to be(false)
        expect(subject.stale?(double(TESTS[1][:data].merge(message: nil)))).to be(false)
      end
    end
  end

  describe "#save" do
    let(:empty_test_run){ double results: [] }

    it "should create the directory of the cache file" do
      subject.save empty_test_run
      expect(File.directory?(File.dirname(cache_file))).to be(true)
    end

    it "should save an empty test run" do
      subject.save empty_test_run
      expect(File.read(cache_file)).to eq(build_cache_contents)
    end

    it "should save test result keys and their hashes" do
      tests = TESTS[0, 2]
      subject.save double(results: tests.collect{ |d| double d[:data] })
      expect(File.read(cache_file)).to eq(build_cache_contents(tests))
    end

    it "should raise an error with no workspace" do
      expect{ Cache.new(cache_options.merge(workspace: nil)).save empty_test_run }.to raise_error(Cache::Error, /workspace/i)
    end

    it "should raise an error with no server name" do
      expect{ Cache.new(cache_options.merge(server_name: nil)).save empty_test_run }.to raise_error(Cache::Error, /server name/i)
    end

    it "should raise an error with no project api id" do
      expect{ Cache.new(cache_options.merge(project_api_id: nil)).save empty_test_run }.to raise_error(Cache::Error, /project API identifier/i)
    end

    describe "when loaded" do
      before :each do
        FileUtils.mkdir_p File.dirname(cache_file)
        File.open(cache_file, 'w'){ |f| f.write cache_contents }
        subject.load
      end

      it "should update the hashes of changed tests" do
        subject.save double(results: TESTS.collect{ |d| double d[:data] })
        expect(File.read(cache_file)).to eq(build_cache_contents(TESTS, actual: true))
      end

      context "with old data from another project" do
        subject{ Cache.new cache_options.merge(project_api_id: '234') }

        it "should drop the old data" do
          expect(File.read(cache_file)).to eq(build_cache_contents(TESTS))
          subject.save double(results: TESTS.collect{ |d| double d[:data] })
          expect(File.read(cache_file)).to eq(build_cache_contents(TESTS, project_api_id: '234', actual: true))
        end
      end
    end
  end

  def cache_file options = {}
    options = cache_options.merge options
    File.join options[:workspace], 'rspec', 'servers', options[:server_name], 'cache.json'
  end

  def build_cache_contents data = [], options = {}
    %|{"#{options[:project_api_id] || cache_options[:project_api_id]}":{|.tap do |contents|
      contents << data.collect{ |d| %|"#{d[:data][:key]}":"#{options[:actual] ? d[:actual_hash] || d[:hash] : d[:hash]}"| }.join(',')
      contents << %|}}|
    end
  end
end
