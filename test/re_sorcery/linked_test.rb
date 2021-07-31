# frozen_string_literal: true

require "test_helper"

module ReSorcery
  class LinkedTest < Minitest::Test
    include Result

    SELF_LINK = { rel: 'self', href: '/me', method: 'get', type: 'application/json' }.freeze

    class SelfLink
      include Linked
      links do
        link 'self', '/me', 'get', 'application/json'
      end
    end

    class MyObject
      include Linked
      attr_reader :id, :current_user

      def initialize(id, current_user)
        @id = id
        @current_user = current_user
      end

      links do
        link 'self', "/my_objects/#{id}"
        link 'update', "/my_objects/#{id}", 'put' if current_user.can_update?(self)
        link 'destroy', "/my_objects/#{id}", 'delete' if current_user.can_destroy?(self)
      end
    end

    class EasySelfLink
      include Linked
      links do
        link 'self', '/me'
      end
    end

    class ConditionalLink
      include Linked
      attr_accessor :use_link
      def initialize(use_link)
        @use_link = use_link
      end
      links do
        link 'self', '/me' if use_link
      end
    end

    class InvalidRelLink
      include Linked
      links do
        link 'not allowed', '/me'
      end
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

    def test_links_multiple_times_stay_the_same
      self_link = SelfLink.new
      assert_equal ok([SELF_LINK]), self_link.links
      assert_equal ok([SELF_LINK]), self_link.links
      assert_equal ok([SELF_LINK]), self_link.links
      assert_equal ok([SELF_LINK]), self_link.links
    end

    def test_links_block_is_not_cached
      conditional_link = ConditionalLink.new(true)
      assert_equal ok([SELF_LINK]), conditional_link.links
      assert_equal ok([SELF_LINK]), conditional_link.links

      conditional_link.use_link = false
      assert_equal ok([]), conditional_link.links

      conditional_link.use_link = true
      assert_equal ok([SELF_LINK]), conditional_link.links
    end
  end
end
