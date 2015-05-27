require 'helper'

describe ProbeDockRSpec::TestResult do
  let(:project_options){ { category: 'A category', tags: %w(a b), tickets: %w(t1 t2) } }
  let(:project_double){ double project_options }
  let(:example_metadata){ { key: '123' } }
  let(:example_double){ double description: 'should work', metadata: { probe_dock: example_metadata } }
  let(:group_doubles){ [ group_double('Something') ] }
  let(:result_options){ { passed: true, duration: 42 } }
  let(:result){ ProbeDockRSpec::TestResult.new project_double, example_double, group_doubles, result_options }
  subject{ result }

  it "should use the example key" do
    expect(subject.key).to eq('123')
  end

  it "should build the name from the group's and example's descriptions" do
    expect(subject.name).to eq("Something should work")
  end

  it "should use the category, tags and tickets of the project" do
    expect(subject.category).to eq(project_options[:category])
    expect(subject.tags).to eq(project_options[:tags])
    expect(subject.tickets).to eq(project_options[:tickets])
  end

  it "should use the supplied result data" do
    expect(subject.passed?).to be(true)
    expect(subject.duration).to eq(42)
    expect(subject.message).to be_nil
  end

  describe "when the key replaces the options" do
    let(:example_metadata){ '123' }

    it "should use the example key" do
      expect(subject.key).to eq('123')
    end
  end

  describe "when failing" do
    let(:result_options){ { passed: false, duration: 12, message: 'Oops' } }

    it "should use the supplied result data" do
      expect(subject.passed?).to be(false)
      expect(subject.duration).to eq(12)
      expect(subject.message).to eq('Oops')
    end
  end

  describe "when grouped" do
    let(:example_metadata){ super().tap{ |h| h.delete :key } }
    let :group_doubles do
      super() + [
        group_double('default attributes', key: '234', grouped: true),
        group_double('whatever')
      ]
    end

    it "should mark the result as grouped" do
      expect(subject.grouped?).to be(true)
    end

    it "should use the grouped key" do
      expect(subject.key).to eq('234')
    end

    it "should build the name from the groups' descriptions up the grouped marker" do
      expect(subject.name).to eq("Something default attributes")
    end
  end

  describe "with many groups" do
    let :group_doubles do
      super() + [
        group_double('when created', category: 'Another category'),
        group_double('with this', tags: 'c'),
        group_double('and that', tickets: %w(t3 t4))
      ]
    end

    it "should build the name from the groups' and example's descriptions" do
      expect(subject.name).to eq("Something when created with this and that should work")
    end

    it "should override the category and add new tags and tickets" do
      expect(subject.category).to eq('Another category')
      expect(subject.tags).to eq(project_options[:tags] + %w(c))
      expect(subject.tickets).to eq(project_options[:tickets] + %w(t3 t4))
    end

    describe "and a custom category, tags and tickets" do
      let(:example_metadata){ super().merge category: 'Yet another category', tags: 'd', tickets: 't5' }

      it "should override the category and add new tags and tickets" do
        expect(subject.category).to eq('Yet another category')
        expect(subject.tags).to eq(project_options[:tags] + %w(c d))
        expect(subject.tickets).to eq(project_options[:tickets] + %w(t3 t4 t5))
      end
    end
  end

  describe "#update" do
    let(:updates){ [] }
    subject{ super().tap{ |s| updates.each{ |u| s.update u } } }

    it "should not concatenate missing messages" do
      subject.update passed: true, duration: 1
      subject.update passed: true, duration: 2
      subject.update passed: true, duration: 3
      expect(subject.message).to be_nil
    end

    describe "with failing result data" do
      let(:update_options){ { passed: false, duration: 24, message: 'Foo' } }
      let(:updates){ super() << update_options }

      it "should mark the result as failed" do
        expect(subject.passed?).to be(false)
      end

      it "should increase the duration" do
        expect(subject.duration).to eq(66)
      end

      it "should set the message" do
        expect(subject.message).to eq('Foo')
      end

      describe "and passing result data" do
        let(:other_update_options){ { passed: true, duration: 600, message: 'Bar' } }
        let(:updates){ super() << other_update_options }

        it "should keep the result marked as failed" do
          expect(subject.passed?).to be(false)
        end

        it "should increase the duration" do
          expect(subject.duration).to eq(666)
        end

        it "should concatenate the messages" do
          expect(subject.message).to eq("Foo\n\nBar")
        end
      end
    end
  end

  describe "#to_h" do
    let(:to_h_options){ {} }
    let(:result_options){ super().merge message: 'Yeehaw!' }
    subject{ super().to_h to_h_options }

    let :expected_result do
      {
        'k' => '123',
        'n' => 'Something should work',
        'p' => true,
        'd' => 42,
        'm' => 'Yeehaw!',
        'c' => 'A category',
        'g' => [ 'a', 'b' ],
        't' => [ 't1', 't2' ]
      }
    end

    it "should serialize the result" do
      expect(subject).to eq(expected_result)
    end

    describe "with no message, category, tags or tickets" do
      let(:project_options){ { category: nil, tags: nil, tickets: nil } }
      let(:result_options){ super().merge message: nil }

      it "should not include them" do
        expect(subject).to eq(expected_result.delete_if{ |k,v| %w(m c g t).include? k })
      end
    end

    describe "with a cache" do
      let(:cache_double){ double known?: false, stale?: false }
      let(:to_h_options){ super().merge cache: cache_double }

      it "should serialize the result" do
        expect(subject).to eq(expected_result)
      end

      describe "when cached" do
        let(:cache_double){ double known?: true, stale?: false }
        let(:to_h_options){ super().merge cache: cache_double }

        it "should serialize the result without known data" do
          expect(subject).to eq(expected_result.delete_if{ |k,v| %w(n c g t).include? k })
        end

        describe "and stale" do
          let(:cache_double){ double known?: true, stale?: true }

          it "should serialize the result" do
            expect(subject).to eq(expected_result)
          end
        end
      end
    end
  end

  describe ".meta" do
    subject{ ProbeDockRSpec::TestResult }

    it "should extract ProbeDock metadata" do
      expect(subject.meta(double(metadata: { probe_dock: { foo: 'bar' } }))).to eq(foo: 'bar')
    end

    it "should extract ProbeDock metadata when the key replaces the options" do
      expect(subject.meta(double(metadata: { probe_dock: 'foo' }))).to eq(key: 'foo')
    end

    it "should not raise an error if there is no ProbeDock metadata" do
      expect(subject.meta(double(metadata: {}))).to eq({})
    end
  end

  describe ".extract_key" do
    subject{ ProbeDockRSpec::TestResult }

    it "should return nil when there is no key" do
      example = double metadata: {}
      groups = [ group_double('a'), group_double('b') ]
      expect(subject.extract_key(example, groups)).to be_nil
    end

    it "should extract the example key" do
      example = double metadata: { probe_dock: { key: 'abc' } }
      expect(subject.extract_key(example, [])).to eq('abc')
    end

    it "should extract the example key when it replaces the options" do
      example = double metadata: { probe_dock: 'abc' }
      expect(subject.extract_key(example, [])).to eq('abc')
    end

    it "should extract the last group key" do
      example = double metadata: {}
      groups = [ group_double('a', key: 'bcd'), group_double('b', key: 'cde'), group_double('c') ]
      expect(subject.extract_key(example, groups)).to eq('cde')
    end

    it "should extract the last group key when it replaces the options" do
      example = double metadata: {}
      groups = [ group_double('a', 'bcd'), group_double('b', 'cde'), group_double('c') ]
      expect(subject.extract_key(example, groups)).to eq('cde')
    end

    it "should override group keys with the example key" do
      example = double metadata: { probe_dock: { key: 'abc' } }
      groups = [ group_double('a', key: 'bcd'), group_double('b', key: 'cde') ]
      expect(subject.extract_key(example, groups)).to eq('abc')
    end
  end

  describe ".extract_grouped" do
    subject{ ProbeDockRSpec::TestResult }

    it "should not indicate a normal example as grouped" do
      example = double metadata: { probe_dock: { key: 'abc' } }
      groups = [ group_double('a'), group_double('b') ]
      expect(subject.extract_grouped(example, groups)).to be(false)
    end

    it "should detect a grouped example" do
      example = double metadata: {}
      groups = [ group_double('a'), group_double('b', key: 'cde', grouped: true) ]
      expect(subject.extract_grouped(example, groups)).to be(true)
    end
  end

  def group_double desc, metadata = {}
    double description: desc, metadata: { probe_dock: metadata }
  end
end
