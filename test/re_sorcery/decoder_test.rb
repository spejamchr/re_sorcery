# frozen_string_literal: true

require "test_helper"

module ReSorcery
  class DecoderTest < Minitest::Test
    include Helpers

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
      ReSorcery::Decoder.new { raise "BAD!" },
      -> { raise "Don't run me!" },
    ].freeze

    def test_not_maybe
      refute_kind_of Maybe, Decoder.new
    end

    def test_not_result
      refute_kind_of Result, Decoder.new
    end

    def test_always_decoder
      always = Decoder.new { |n| ok(n) }
      STUFF.each do |thing|
        assert_equal ok(thing), always.test(thing)
      end
    end

    def test_never_decoder
      never = Decoder.new { err("no") }
      STUFF.each do |thing|
        assert_equal err("no"), never.test(thing)
      end
    end

    def test_decoder_auto_ok_shorthand
      always = Decoder.new { true }
      STUFF.each do |thing|
        assert_equal ok(thing), always.test(thing)
      end
    end

    def test_decoder_auto_err_shorthand
      never = Decoder.new { "no" }
      STUFF.each do |thing|
        assert_equal err("no"), never.test(thing)
      end
    end

    def test_decoder_auto_shorthand_realistic
      is_string = Decoder.new { |n| n.is_a?(String) || "Expected String, got #{n.class}" }

      assert_equal ok("string"), is_string.test("string")
      assert_equal err("Expected String, got Symbol"), is_string.test(:symbol)
    end

    def test_decoder_will_not_successfullly_return_nil
      always = Decoder.new { true }
      assert_kind_of Result::Err, always.test(nil)
    end

    def test_map_decoder
      plus_1_integer = Decoder.new { |n| n.is_a?(Integer) }.map { |n| n + 1 }

      assert_equal ok(2), plus_1_integer.test(1)
    end

    def test_map_error_decoder
      fail_with_hi = Decoder.new { false }.map_error { 'hi' }

      assert_equal err('hi'), fail_with_hi.test(2)
    end

    def test_and_then_decoder
      is_hi_there = Decoder.new { |u| %w[hi there].include?(u) }
      is_one_or_two = Decoder.new { |u| [1, 2].include?(u) }
      is_string_int = Decoder.new { |u| u.is_a?(String) || u.is_a?(Integer) }
      and_thened = is_string_int.and_then { |v| v.is_a?(String) ? is_hi_there : is_one_or_two }

      assert_equal err(false), and_thened.test(:symbol)

      assert_equal ok('hi'), and_thened.test('hi')
      assert_equal ok(1), and_thened.test(1)

      assert_equal err(false), and_thened.test(3)
      assert_equal err(false), and_thened.test('hello')
    end

    def test_and_then_raises_error_on_bad_block
      invalid_decoder = Decoder.new { true }.and_then { 2 }

      assert_raises(ReSorcery::Error::ArgumentError) { invalid_decoder.test('anything') }
    end

    def test_assign_decoder
      has_name = Decoder.new { |u| u[:name].is_a?(String) && ok(u[:name]) || "name err: #{u.inspect}" }
      has_age = Decoder.new { |u| u[:age].is_a?(Integer) && ok(u[:age]) || "age err: #{u.inspect}" }

      user_decoder = Decoder.new { ok({}) }
        .assign(:name, has_name)
        .assign(:age, has_age)

      user = { name: "Gilbert", age: 14 }

      assert_equal ok(user), user_decoder.test(user)
    end

    def test_assign_raises_error_on_non_hash_decoder
      assert_raises(ReSorcery::Error::ArgumentError) do
        Decoder.new { ok(:not_hash) }
          .assign(:f, Decoder.new { ok('hi') })
          .test('anything')
      end
    end

    def test_assign_block_does_not_run_on_failing_decoder
      Decoder.new { err('fail') }
        .assign(:f, -> { raise 'should not run' })
        .test('anything')
    end
  end
end
