# frozen_string_literal: true

require "test_helper"

module LinkedPayload
  class MaybeTest < Minitest::Test
    include LinkedPayload::Maybe
    extend LinkedPayload::Maybe

    ADD_1 = ->(n) { n + 1 }
    DO_NOT_RUN = -> { raise "Shouldn't run" }

    def test_equality
      assert_equal just(nothing), just(nothing)
      refute_equal just(1), nothing
      refute_equal 1, just(1)
      refute_equal 1, nothing
    end

    def test_just_and_then
      assert_equal(just(1), just(0).and_then { |n| just(n + 1) })
      assert_equal(nothing, just(0).and_then { nothing })
    end

    def test_just_and_then_raises_on_non_result
      assert_raises(LinkedPayload::Error::LinkedPayloadError) { just(1).and_then(&ADD_1) }
    end

    def test_nothing_and_then
      assert_equal nothing, nothing.and_then(&DO_NOT_RUN)
    end

    def test_map
      assert_equal just(1), just(0).map(&ADD_1)
      assert_equal nothing, nothing.map(&DO_NOT_RUN)
    end

    def test_just_or_else
      assert_equal just(1), just(1).or_else(&DO_NOT_RUN)
    end

    def test_nothing_or_else
      assert_equal(nothing, nothing.or_else { nothing })
      assert_equal(just(1), nothing.or_else { just(1) })
    end

    def test_nothing_or_else_raises_on_non_result
      assert_raises(LinkedPayload::Error::LinkedPayloadError) { nothing.or_else { 1 } }
    end

    def test_just_assign
      assert_equal(just(a: 1), just({}).assign(:a) { just(1) })
      assert_equal(nothing, just({}).assign(:a) { nothing })
    end

    def test_just_assign_raises_on_non_result
      assert_raises(LinkedPayload::Error::LinkedPayloadError) { just({}).assign(:a) { 1 } }
    end

    def test_just_assign_raises_on_non_hash_value
      assert_raises(LinkedPayload::Error::LinkedPayloadError) { just(0).assign(:a, &ADD_1) }
    end

    def test_nothing_assign_does_not_run
      assert_equal nothing, nothing.assign(:a, &DO_NOT_RUN)
    end

    def test_just_as_json
      assert_equal({ kind: :just, value: 1 }, just(1).as_json)
    end

    def test_nothing_as_json
      assert_equal({ kind: :nothing }, nothing.as_json)
    end

    def test_nillable
      assert_equal just(2), nillable(2)
      assert_equal nothing, nillable(nil)
    end
  end
end
