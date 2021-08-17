# frozen_string_literal: true

require "test_helper"

module ReSorcery
  module Configuration
    class LinkMethodsConfigurationTest < Minitest::Test
      METHOD = 'non_default'

      def setup
        teardown
        ReSorcery::Linked.instance_exec { @link_class = nil }
        ReSorcery.configure { link_methods [METHOD] }
      end

      def teardown
        ReSorcery::Linked.instance_exec { @link_class = nil }
        ReSorcery.instance_exec { @configuration = @configured = nil }
      end

      def klass_with_method(method)
        re_sorceried_klass { links { link 'self', '/', method } }
      end

      def test_configure_valid_link_methods_works
        assert_equal [METHOD], ReSorcery.configuration[:link_methods]
      end

      def test_newly_valid_link_method
        klass = klass_with_method(METHOD)
        assert_at_json METHOD, klass.new.as_json, [:value, :links, 0, :method]
      end

      def test_now_invalid_link_method
        klass = klass_with_method('get')
        json = klass.new.as_json
        assert_equal :err, json[:kind], json
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
