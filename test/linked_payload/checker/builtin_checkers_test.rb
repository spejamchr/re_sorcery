# frozen_string_literal: true

require "test_helper"

module LinkedPayload
  class Checker
    class BuiltinCheckersTest < Minitest::Test
      include LinkedPayload::Result
      include LinkedPayload::Checker::BuiltinCheckers

      class MyString < String; end

      def oks(checker, items)
        items.each { |i| assert_kind_of Ok, checker.check(i) }
      end

      def errs(checker, items)
        items.each { |i| assert_kind_of Err, checker.check(i) }
      end

      def test_string_checker_passes_strings
        oks is(String), ["hi", "there\n you", "\n\n", MyString.new("hi"), ('b' * 1000)]
      end

      def test_string_checker_fails_non_strings
        errs is(String), [1, :symbol, ["array"], { a: 'hash' }, (1..2), ('a'..'b'), Set.new, String]
      end

      def test_is_numeric_checkers_passes_numerics
        oks is(Numeric), [1, 1.1, 1i, 3/4r, 1.1i, 3ri / 4, 3ri / 4.1r, 7**7**7]
      end

      def test_is_numeric_checker_fails_non_numerics
        errs is(Numeric), ['1', :one, [1], { a: 2 }, (1..2), ('a'..'b'), Set.new, String]
      end

      def test_is_with_object_checker_passes
        ['a', ('b' * 1000), { a: ['b'] }, [1, 2, 4], Set.new, 7**7**7, 4i / 3r].each do |o|
          assert_kind_of Ok, is(o).check(o)
        end
      end

      def test_is_with_object_checker_uses_equality_not_identity
        oks is(1), [1.0, 1.0 + 0i, 1r]
      end

      def test_is_with_object_checker_fails
        {
          'a' => [:a, ['a'], { a: 'a' }, 1],
          a: ['a', [:a], { a: 'a' }, 1],
          1 => [2, 1.1, 1 + 1i, [1], { 1 => 1 }, :sym],
          [1] => [1, [2], { 1 => 1 }, :sym],
        }.each do |k, vs|
          vs.each { |v| assert_kind_of Err, is(k).check(v) }
        end
      end

      def test_is_with_many_checkers
        c = is(is('a'), is('b'), is('c'), is('d'), is(Numeric))

        oks c, ['a', 'b', 'c', 'd', 1, 1.1, 2i, 3/4r]

        errs c, ['e', 'f', :sym, [], {}, String, Numeric]
      end

      def test_is_with_many_classes
        c = is(String, Symbol)

        oks c, ['a', 'b', :c, :d]

        errs c, [String, Symbol, 1, 2, ['hi'], [:there]]
      end

      def test_is_with_many_objects
        c = is(:a, 'a', 0, [], {}, Set.new, (0..1))

        oks c, [:a, 'a', 0, [], {}, Set.new, (0..1)]

        errs c, [:b, 'b', 1, [nil], { nil => nil }, Set.new([1]), (0...1)]
      end

      def test_is_with_multiple_human_bools
        human_bool = is('yes', 'no')

        assert_equal ok('yes'), human_bool.check('yes')
        assert_equal ok('no'), human_bool.check('no')

        errs human_bool, ['other', 'maybe', 'yes ', "no\n"]
      end

      def test_is_rejects_nil
        assert_raises(LinkedPayload::Error::LinkedPayloadError) { is(nil) }
      end

      def test_array_with_checker
        c = array(is(Numeric))

        assert_kind_of Ok, c.check([1, 2.2, 3r, -2])

        errs c, [
          ['a', 1, 2.2, 3r, -2],
          [1, 2.2, nil, 3r, -2],
          [1, 2.2, 3r, :sym, -2],
          [1, 2.2, 3r, -2, []],
        ]
      end

      def test_array_with_class
        c = array(Numeric)

        assert_kind_of Ok, c.check([1, 2.2, 3r, -2])

        errs c, [
          ['a', 1, 2.2, 3r, -2],
          [1, 2.2, nil, 3r, -2],
          [1, 2.2, 3r, :sym, -2],
          [1, 2.2, 3r, -2, []],
        ]
      end

      def test_array_with_object
        c = array(1)

        oks c, [[], [1], [1, 1, 1, 1, 1, 1]]

        errs c, [[nil], [2], [1, 1, 1, 1, 2, 1, 1, 1]]
      end
    end
  end
end
