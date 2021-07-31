# frozen_string_literal: true

require "test_helper"

module ReSorcery
  class ResultTest < Minitest::Test
    include ReSorcery::Result

    STUFF = [
      1,
      '1',
      :one,
      [1, '1', :one],
      { 1 => '1', one: [] },
      Set.new([1, [], '1']),
      (1..11),
      String,
      Class,
      Module,
      ReSorcery::Checker.new { raise "BAD!" },
      -> { raise "Don't run me!" },
    ].freeze

    def test_always_checker
      always = Checker.new { |n| ok(n) }
      STUFF.each do |thing|
        assert_equal ok(thing), always.check(thing)
      end
    end

    def test_never_checker
      never = Checker.new { err("no") }
      STUFF.each do |thing|
        assert_equal err("no"), never.check(thing)
      end
    end

    def test_checker_auto_ok_shorthand
      always = Checker.new { true }
      STUFF.each do |thing|
        assert_equal ok(thing), always.check(thing)
      end
    end

    def test_checker_auto_err_shorthand
      never = Checker.new { "no" }
      STUFF.each do |thing|
        assert_equal err("no"), never.check(thing)
      end
    end

    def test_checker_auto_shorthand_realistic
      is_string = Checker.new { |n| n.is_a?(String) || "Expected String, got #{n.class}" }

      assert_equal ok("string"), is_string.check("string")
      assert_equal err("Expected String, got Symbol"), is_string.check(:symbol)
    end

    def test_checker_will_not_successfullly_return_nil
      always = Checker.new { true }
      assert_kind_of Err, always.check(nil)
    end
  end
end
