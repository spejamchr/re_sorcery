# frozen_string_literal: true

require "test_helper"

module ReSorcery
  module Configuration
    class LinkMethodsConfigurationTest < Minitest::Test
      METHOD = 'non_default'

      def setup
        clear_re_sorcery_config
        ReSorcery.configure { link_methods [METHOD] }
      end

      def teardown
        clear_re_sorcery_config
      end

      def klass_with_method(method)
        re_sorceried_klass { links { link 'self', '/', method } }
      end

      def test_configure_valid_link_methods_works
        assert_equal [METHOD], ReSorcery.configuration[:link_methods]
      end

      def test_newly_valid_link_method
        klass = klass_with_method(METHOD)
        assert_at_json METHOD, klass.new.as_json, [:links, 0, :method]
      end

      def test_now_invalid_link_method
        klass = klass_with_method('get')
        assert_raises(ReSorcery::Error::InvalidResourceError) { klass.new.as_json }
      end

      def test_configure_invalid_methods
        teardown
        assert_raises(Error::ArgumentError) { ReSorcery.configure { link_methods 'not an array' } }
        teardown
        assert_raises(Error::ArgumentError) { ReSorcery.configure { link_methods %i[not strings] } }
      end
    end
  end
end
