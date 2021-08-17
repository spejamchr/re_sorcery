# frozen_string_literal: true

require "test_helper"

module ReSorcery
  module Configuration
    class LinkRelsConfigurationTest < Minitest::Test
      REL = 'non_default'

      def setup
        teardown
        ReSorcery::Linked.instance_exec { @link_class = nil }
        ReSorcery.configure { link_rels [REL] }
      end

      def teardown
        ReSorcery::Linked.instance_exec { @link_class = nil }
        ReSorcery.instance_exec { @configuration = @configured = nil }
      end

      def klass_with_rel(rel)
        re_sorceried_klass { links { link rel, '/' } }
      end

      def test_configure_valid_link_rels_works
        assert_equal [REL], ReSorcery.configuration[:link_rels]
      end

      def test_newly_valid_link_rel
        klass = klass_with_rel(REL)
        assert_at_json REL, klass.new.as_json, [:value, :links, 0, :rel]
      end

      def test_now_invalid_link_rel
        klass = klass_with_rel('self')
        json = klass.new.as_json
        assert_equal :err, json[:kind], json
      end

      def test_configure_invalid_rels
        teardown
        assert_raises(Error::ArgumentError) { ReSorcery.configure { link_rels 'not an array' } }
        teardown
        assert_raises(Error::ArgumentError) { ReSorcery.configure { link_rels %i[not strings] } }
      end
    end
  end
end
