# frozen_string_literal: true

require "test_helper"
require "set"

module ReSorcery
  class Decoder
    class BuiltinDecodersTest < Minitest::Test
      include BuiltinDecoders
      include Helpers

      class MyString < String; end

      def oks(decoder, items)
        items.each { |i| assert_equal ok(i), decoder.test(i) }
      end

      def errs(decoder, items)
        items.each { |i| assert_kind_of Result::Err, decoder.test(i) }
      end

      def test_string_decoder_passes_strings
        oks is(String), ["hi", "there\n you", "\n\n", MyString.new("hi"), ('b' * 1000)]
      end

      def test_string_decoder_fails_non_strings
        errs is(String), [1, :symbol, ["array"], { a: 'hash' }, (1..2), ('a'..'b'), Set.new, String]
      end

      def test_is_numeric_decoders_passes_numerics
        oks is(Numeric), [1, 1.1, 1i, 3/4r, 1.1i, 3ri / 4, 3ri / 4.1r, 7**7**7]
      end

      def test_is_numeric_decoder_fails_non_numerics
        errs is(Numeric), ['1', :one, [1], { a: 2 }, (1..2), ('a'..'b'), Set.new, String]
      end

      def test_is_with_object_decoder_passes
        ['a', ('b' * 1000), { a: ['b'] }, [1, 2, 4], Set.new, 7**7**7, 4i / 3r].each do |o|
          assert_kind_of Result::Ok, is(o).test(o)
        end
      end

      def test_is_with_object_decoder_uses_eql_not_identity
        oks is("hi", ["hi"], {}), ["hi", ["hi"], {}]

        errs is(1), [1.0, 1.0 + 0i, 1r]
      end

      def test_is_with_object_decoder_fails
        {
          'a' => [:a, ['a'], { a: 'a' }, 1],
          a: ['a', [:a], { a: 'a' }, 1],
          1 => [2, 1.1, 1 + 1i, [1], { 1 => 1 }, :sym],
          [1] => [1, [2], { 1 => 1 }, :sym],
        }.each do |k, vs|
          vs.each { |v| assert_kind_of Result::Err, is(k).test(v) }
        end
      end

      def test_is_with_many_decoders
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

        assert_equal ok('yes'), human_bool.test('yes')
        assert_equal ok('no'), human_bool.test('no')

        errs human_bool, ['other', 'maybe', 'yes ', "no\n"]
      end

      def test_is_with_multiple_different_types
        thing = Object.new
        specific_object = Decoder.new { |u| u == thing || "Expected a specific Object instance" }
        c = is(specific_object, is(Complex), String, Symbol, [], [:a], 0)

        oks c, [thing, 1i, "hi", :symbol, [], [:a], 0]

        errs c, [Object.new, 1, [:invalid, "array"], 2]
      end

      def test_is_rejects_nil
        assert_raises(ReSorcery::Error::ReSorceryError) { is(nil) }
      end

      def test_array_with_decoder
        c = array(is(Numeric))

        assert_kind_of Result::Ok, c.test([1, 2.2, 3r, -2])

        errs c, [
          ['a', 1, 2.2, 3r, -2],
          [1, 2.2, nil, 3r, -2],
          [1, 2.2, 3r, :sym, -2],
          [1, 2.2, 3r, -2, []],
        ]
      end

      def test_array_with_class
        c = array(Numeric)

        assert_kind_of Result::Ok, c.test([1, 2.2, 3r, -2])

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

      def test_array_with_transforming_decoder
        c = array(is(String).map(&:to_sym))

        a = %w[hi there]

        assert_equal ok(a.map(&:to_sym)), c.test(a)
      end

      def test_non_empty_array_with_transforming_decoder
        c = non_empty_array(is(String).map(&:to_sym))

        a = %w[hi there]

        assert_equal ok(a.map(&:to_sym)), c.test(a)
      end

      def test_non_empty_array_followed_by_transforming_decoder
        c = non_empty_array(String).map { |arr| arr.map(&:to_sym) }

        a = %w[hi there]

        assert_equal ok(a.map(&:to_sym)), c.test(a)
      end

      def test_non_empty_array_fails_when_empty
        c = non_empty_array(String)

        oks c, [["hi"], [""], %w[a b c]]

        errs c, [[]]
      end

      def test_maybe_with_decoder
        c = maybe(is(Numeric))

        oks c, [just(1), just(2.3), just(-1), just(5i), just(4/5r), nothing]

        errs c, [just('hi'), just(:sym), just([8])]
      end

      def test_maybe_with_several_types
        c = maybe(Numeric, Symbol, 'hi', 'there')

        oks c, [just(1), just(2.3), just(-1), just(:sym), just('hi'), just('there'), nothing]

        errs c, [just('no'), just([:sym]), just({ key: 8 })]
      end

      def test_field_decoder
        d = field(:f, String)

        [{ f: 'hi' }, { a: 1, f: '' }, { a: [], b: {}, f: 'Howdy!' }].each do |h|
          assert_equal ok(h[:f]), d.test(h), "Broke on: #{h.inspect}"
        end

        errs d, [{ f: :not_string }, { a: :missing_f }, {}]
      end
    end
  end
end
