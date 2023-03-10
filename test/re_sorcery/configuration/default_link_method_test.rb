# frozen_string_literal: true

require "test_helper"

module ReSorcery
  module Configuration
    class DefaultLinkMethodTest < Minitest::Test
      METHOD = "diff_method"
      def setup
        clear_re_sorcery_config

        ReSorcery.configure { 
          link_methods ["first_method", METHOD]
          default_link_method ->(a) { a.last }
        }
      end

      def teardown
        clear_re_sorcery_config
      end

      def klass_with_link
        re_sorceried_klass { links { link 'self', '/' } }
      end

      def test_newly_valid_link_method
        assert_at_json METHOD, klass_with_link.new.as_json, [:links, 0, :method]
      end

    end
  end
end

