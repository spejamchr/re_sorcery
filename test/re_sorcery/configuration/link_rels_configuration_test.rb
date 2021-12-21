# frozen_string_literal: true

require "test_helper"

module ReSorcery
  module Configuration
    class LinkRelsConfigurationTest < Minitest::Test
      REL = 'non_default'

      def setup
        clear_re_sorcery_config
        ReSorcery.configure { link_rels [REL] }
      end

      def teardown
        clear_re_sorcery_config
      end

      def klass_with_rel(rel)
        re_sorceried_klass { links { link rel, '/' } }
      end

      def test_configure_valid_link_rels_works
        assert_equal [REL], ReSorcery.configuration[:link_rels]
      end

      def test_newly_valid_link_rel
        klass = klass_with_rel(REL)
        assert_at_json REL, klass.new.as_json, [:links, 0, :rel]
      end

      def test_now_invalid_link_rel
        klass = klass_with_rel('self')
        assert_raises(ReSorcery::Error::InvalidResourceError) { klass.new.as_json }
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
