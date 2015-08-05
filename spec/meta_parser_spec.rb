require 'helper'

RSpec.describe ProbeDockRSpec::MetaParser do
  let(:example_metadata){ {} }
  let(:example_arg){ example_double 'should work', example_metadata }
  let(:groups_arg){ [ group_double('Something') ] }
  let(:sample_fingerprint){ '66d8e9645db2878b53b6dd51acb672e97c389c87' }
  subject{ described_class.parse example_arg, groups_arg }

  it "should extract the name and fingerprint of a test with no metadata" do
    expect_result_options({
      name: 'Something should work',
      fingerprint: sample_fingerprint
    })
  end

  describe "with multiple groups" do
    let(:groups_arg){ [ group_double('A'), group_double('b'), group_double('c') ] }
    let(:sample_fingerprint){ '1c22e0ad110dc5b07761beec69712267fc384152' }

    it "should build the name and fingerprint by concatenating all group descriptions and the example description" do
      expect_result_options({
        name: 'A b c should work',
        fingerprint: sample_fingerprint
      })
    end

    describe "with categories, tags and tickets" do
      let(:groups_arg) do
        [
          group_double('A', category: 'unit', tags: %w(a b c)),
          group_double('b', tickets: %w(t1 t3)),
          group_double('c', category: 'integration', tags: %w(a c d), tickets: %w(t1 t2 t4))
        ]
      end

      it "should override the category and combine the tags and tickets" do
        expect_result_options({
          name: 'A b c should work',
          fingerprint: sample_fingerprint,
          category: 'integration',
          tags: %w(a b c d),
          tickets: %w(t1 t2 t3 t4)
        })
      end

      describe "and a category, tags and tickets at the level of the test" do
        let(:example_arg){ example_double 'should work', category: 'performance', tags: %w(a e), tickets: %w(t2 t4) }

        it "should override the category and combine the tags and tickets" do
          expect_result_options({
            name: 'A b c should work',
            fingerprint: sample_fingerprint,
            category: 'performance',
            tags: %w(a b c d e),
            tickets: %w(t1 t2 t3 t4)
          })
        end
      end
    end
  end

  describe "with metadata containing a key" do
    let(:example_arg){ example_double 'should work', key: 'abc' }

    it "should extract the key from the metadata" do
      expect_result_options({
        key: 'abc',
        name: 'Something should work',
        fingerprint: sample_fingerprint
      })
    end
  end

  describe "with metadata containing a category" do
    let(:example_arg){ example_double 'should work', category: 'integration' }

    it "should extract the category from the metadata" do
      expect_result_options({
        name: 'Something should work',
        fingerprint: sample_fingerprint,
        category: 'integration'
      })
    end
  end

  describe "with metadata containing tags" do
    let(:example_arg){ example_double 'should work', tags: %w(a b c) }

    it "should extract the tags from the metadata" do
      expect_result_options({
        name: 'Something should work',
        fingerprint: sample_fingerprint,
        tags: %w(a b c)
      })
    end
  end

  describe "with metadata containing tickets" do
    let(:example_arg){ example_double 'should work', tickets: %w(t1 t2) }

    it "should extract the tickets from the metadata" do
      expect_result_options({
        name: 'Something should work',
        fingerprint: sample_fingerprint,
        tickets: %w(t1 t2)
      })
    end
  end

  describe "with metadata containing custom data" do
    let(:example_arg){ example_double 'should work', data: { foo: 'bar', baz: 'qux' } }

    it "should extract the tickets from the metadata" do
      expect_result_options({
        name: 'Something should work',
        fingerprint: sample_fingerprint,
        data: {
          foo: 'bar',
          baz: 'qux'
        }
      })
    end
  end

  describe "with string metadata" do
    let(:example_arg){ example_double 'should work', 'abc' }

    it "should use the metadata as key" do
      expect_result_options({
        key: 'abc',
        name: 'Something should work',
        fingerprint: sample_fingerprint
      })
    end
  end

  describe "with unexpected metadata" do
    let(:example_arg){ example_double 'should work', 42 }

    it "should extract the name and fingerprint of the test" do
      expect_result_options({
        name: 'Something should work',
        fingerprint: sample_fingerprint
      })
    end
  end

  def example_double desc, metadata = {}
    double description: desc, metadata: { probe_dock: metadata }
  end

  def group_double desc, metadata = {}
    double description: desc, metadata: { probe_dock: metadata }
  end

  def expect_result_options options = {}

    result_options = {
      key: nil,
      category: nil,
      tags: [],
      tickets: [],
      data: {}
    }.merge(options)

    result_options[:tags].sort! if result_options[:tags]
    result_options[:tickets].sort! if result_options[:tickets]
    result_options[:data]['fingerprint'] = result_options[:fingerprint] if result_options[:fingerprint]

    actual = subject.dup
    actual[:tags] = actual[:tags].dup.sort if actual.key? :tags
    actual[:tickets] = actual[:tickets].dup.sort if actual.key? :tickets

    expect(actual).to eq(result_options)
  end
end
