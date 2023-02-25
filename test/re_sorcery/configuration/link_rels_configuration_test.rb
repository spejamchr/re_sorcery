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

      def test_configure_with_symbols_works
        clear_re_sorcery_config
        syms = %i[self child]
        ReSorcery.configure { link_rels syms }
        assert_equal syms.map(&:to_s), ReSorcery.configuration[:link_rels]
        klass = klass_with_rel(:self)
        assert_at_json "self", klass.new.as_json, [:links, 0, :rel]
      end

      def test_configure_empty_array
        clear_re_sorcery_config
        assert_raises(Error::ArgumentError) { ReSorcery.configure { link_rels [] } }
      end

      def test_configure_invalid_rels
        clear_re_sorcery_config
        assert_raises(Error::ArgumentError) { ReSorcery.configure { link_rels 'not an array' } }
      end
    end
  end
end
