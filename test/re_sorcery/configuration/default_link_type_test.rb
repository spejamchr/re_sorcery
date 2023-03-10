# frozen_string_literal: true

require "test_helper"

module ReSorcery
  module Configuration
    class DefaultLinkTypeTest < Minitest::Test
      TYPE = "diff_type"

      def setup
        clear_re_sorcery_config

        ReSorcery.configure { 
          default_link_type TYPE
        }
      end

      def teardown
        clear_re_sorcery_config
      end

      def klass_with_link
        re_sorceried_klass { links { link 'self', '/' } }
      end

      def test_newly_valid_link_method
        assert_at_json TYPE, klass_with_link.new.as_json, [:links, 0, :type]
      end

    end
  end
end


