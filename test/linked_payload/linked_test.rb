# frozen_string_literal: true

require "test_helper"

module LinkedPayload
  class LinkedTest < Minitest::Test
    include LinkedPayload::Result

    SELF_LINK = { rel: 'self', href: '/me', method: 'get', type: 'application/json' }.freeze

    class SelfLink
      include Linked
      link -> { SELF_LINK }
    end

    class EasySelfLink
      include Linked
      link -> { { rel: 'self', href: '/me' } }
    end

    class ConditionalLink
      include Linked
      attr_reader :use_link
      def initialize(use_link)
        @use_link = use_link
      end
      link -> { use_link ? { rel: 'self', href: '/me' } : nil }
    end

    class InvalidRelLink
      include Linked
      link -> { { rel: 'not allowed', href: '/me' } }
    end

    class NonHashLink
      include Linked
      link -> { 'not a hash' }
    end

    def test_links_for_self_link
      assert_equal ok([SELF_LINK]), SelfLink.new.links
    end

    def test_links_for_easy_self_link
      assert_equal ok([SELF_LINK]), EasySelfLink.new.links
    end

    def test_links_for_conditional_link_true
      assert_equal ok([SELF_LINK]), ConditionalLink.new(true).links
    end

    def test_links_for_conditional_link_false
      assert_equal ok([]), ConditionalLink.new(false).links
    end

    def test_links_for_invalid_rel_link
      assert_kind_of Err, InvalidRelLink.new.links
    end

    def test_links_for_non_hash_link
      assert_kind_of Err, NonHashLink.new.links
    end

    def test_non_proc_link_raises_on_class_definition
      assert_raises(LinkedPayload::Error::LinkedPayloadError) do
        Class.new do
          include Linked
          link SELF_LINK
        end
      end
    end
  end
end
