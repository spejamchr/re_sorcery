# frozen_string_literal: true

require "test_helper"

module ReSorcery
  class ResultTest < Minitest::Test
    include Helpers
    extend Helpers

    ADD_1 = ->(n) { n + 1 }
    OK_ADD_1 = ->(n) { ok(n + 1) }
    ERR_ADD_1 = ->(n) { err(n + 1) }
    DO_NOT_RUN = -> { raise "Shouldn't run" }

    def test_equality
      assert_equal ok(err(ok([1]))), ok(err(ok([1])))
      refute_equal ok(1), err(1)
      refute_equal 1, ok(1)
      refute_equal 1, err(1)
    end

    def test_ok_and_then
      assert_equal ok(1), ok(0).and_then(&OK_ADD_1)
      assert_equal err(1), ok(0).and_then(&ERR_ADD_1)
    end

    def test_ok_and_then_raises_on_non_result
      assert_raises(ReSorcery::Error::ReSorceryError) { ok(1).and_then(&ADD_1) }
    end

    def test_err_and_then
      assert_equal err(1), err(1).and_then(&DO_NOT_RUN)
    end

    def test_map
      assert_equal ok(1), ok(0).map(&ADD_1)
      assert_equal err(1), err(1).map(&DO_NOT_RUN)
    end

    def test_map_error
      assert_equal ok(1), ok(1).map_error(&DO_NOT_RUN)
      assert_equal err(1), err(0).map_error(&ADD_1)
    end

    def test_ok_or_else
      assert_equal ok(1), ok(1).or_else(&DO_NOT_RUN)
    end

    def test_err_or_else
      assert_equal err(1), err(0).or_else(&ERR_ADD_1)
      assert_equal ok(1), err(0).or_else(&OK_ADD_1)
    end

    def test_err_or_else_raises_on_non_result
      assert_raises(ReSorcery::Error::ReSorceryError) { err(1).or_else(&ADD_1) }
    end

    def test_ok_assign
      assert_equal(ok(a: 1), ok({}).assign(:a) { ok(1) })
      assert_equal(err(1), ok({}).assign(:a) { err(1) })
    end

    def test_ok_assign_raises_on_non_result
      assert_raises(ReSorcery::Error::ReSorceryError) { ok({}).assign(:a) { 1 } }
    end

    def test_ok_assign_raises_on_non_hash_value
      assert_raises(ReSorcery::Error::ReSorceryError) { ok(0).assign(:a, &ADD_1) }
    end

    def test_err_assign_does_not_run
      assert_equal err(1), err(1).assign(:a, &DO_NOT_RUN)
    end

    def test_ok_as_json
      assert_equal({ kind: :ok, value: 1 }, ok(1).as_json)
    end

    def test_err_as_json
      assert_equal({ kind: :err, value: 1 }, err(1).as_json)
    end
  end
end
