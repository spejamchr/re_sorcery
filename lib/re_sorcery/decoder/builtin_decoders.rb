# frozen_string_literal: true

require 'set'

module ReSorcery
  class Decoder
    # Common decoders implemented here for convenience
    module BuiltinDecoders
      include Helpers

      private

      # A Decoder that always succeeds with a given value
      #
      # Useful for starting decoder chains that build up successful values.
      def succeed(value)
        Decoder.new { ok(value) }
      end

      # A decoder that always fails with some error message
      #
      # Useful for starting decoder chains that search for a successful value.
      def fail(message = '`fail` Decoder always fails')
        ArgCheck['message', message, String]

        Decoder.new { message }
      end

      # Test if an object is_a?(first_mod) (or is one of a list of modules)
      #
      # Note that classes are also modules.
      #
      # In general prefer `#is`.
      #
      # @param [Module] first_mod
      # @param [Array<Module>] others
      # @return [Decoder]
      def mod(first_mod, *others)
        all_mods = ([first_mod] + others).map.with_index { |o, i| ArgCheck["mods[#{i}]", o, Module] }
        raise ReSorcery::Error::ArgumentError, "Do not use `nil`" if all_mods.include?(NilClass)

        mods = all_mods.select { |m| ((m.ancestors - [m]) & all_mods).empty? }

        msg = lambda {
          prefix = mods.count == 1 ? "Expected" : "Expected one of"
          "#{prefix} (#{mods.join(' | ')}) but received"
        }

        Decoder.new { |u| mods.any? { |m| u.is_a?(m) } || "#{msg.call}: #{u.class}" }
      end

      # Test if an object is one of a specific set of things
      #
      # In general prefer `#is`.
      def one_of_exactly(thing, *others)
        things = ([thing] + others).to_set
        nillish = things.include?(nil)
        raise ReSorcery::Error::ArgumentError, "Do not use `nil`" if nillish

        msg = lambda {
          prefix = things.count == 1 ? "Expected exactly" : "Expected one of exactly"
          "#{prefix} (#{things.map(&:inspect).join(' | ')}) but received"
        }

        Decoder.new { |u| things.include?(u) || "#{msg.call}: #{u.inspect}" }
      end

      # Test if an object is a thing (or one of a list of things)
      #
      # Convenience method for creating common types of `Decoder`s.
      #
      # @param [Decoder|Class|Module|unknown] thing
      # @param [Array<Decoder|Class|Module|unknown>] others
      #
      # Accepts any number of arguments greater than 1. Call the list of
      # arguments `things`.
      #
      # For each argument `thing` in `things`:
      #
      # - If `thing` is a Decoder, return it unchanged.
      # - If `thing` is a Class or Module, create a Decoder that tests whether
      #   an object `is_a?(thing)`.
      # - Otherwise, create a Decoder that tests if an object equals `thing`
      #   (using `==`).
      #
      # Then create a decoder that tests each of these decoders one by one
      # against a given item until one passes or they have all failed.
      #
      # @return [Decoder]
      def is(thing, *others)
        things = [thing] + others
        groups = things.group_by { |t| [t.is_a?(Decoder), t.is_a?(Module)] }
        decoders =
          groups.fetch([true, false], []) +
          (groups[[false, true]].nil? ? [] : [mod(*groups[[false, true]])]) +
          (groups[[false, false]].nil? ? [] : [one_of_exactly(*groups[[false, false]])])

        Decoder.new do |instance|
          test_multiple(decoders, instance).map_error do |errors|
            errors.count == 1 ? errors[0] : "all decoders in `is` failed: (#{errors.join(' | ')})"
          end
        end
      end

      # Test that an object is an array of objects that pass the decoder `is(thing)`
      #
      # @param thing @see `is` for details
      # @param others @see `is` for details
      # @return [Decoder]
      def array(thing, *others)
        decoder = is(thing, *others)
        Decoder.new do |instance|
          is(Array).test(instance).and_then do |arr|
            arr.each_with_index.inject(ok([])) do |result_array, (unknown, index)|
              result_array.and_then do |ok_array|
                decoder.test(unknown)
                  .map { |tested| ok_array << tested }
                  .map_error { |error| "Error at index `#{index}` of Array: #{error}" }
              end
            end
          end
        end
      end

      # Like #array, but test the array contains at least one item
      #
      # @param thing @see `is` for details
      # @param others @see `is` for details
      # @return [Decoder]
      def non_empty_array(thing, *others)
        array(thing, *others).and_then do |a|
          Decoder.new do
            a.empty? ? "Expected a non-empty array, but received an empty array" : ok(a)
          end
        end
      end

      # Test that an object is a Maybe whose `value` passes some `Decoder`
      #
      # @param thing @see `is` for details
      # @param others @see `is` for details
      # @return [Decoder]
      def maybe(thing, *others)
        decoder = is(thing, *others)
        Decoder.new do |instance|
          is(Maybe::Just, Maybe::Nothing).test(instance).and_then do |maybe|
            maybe
              .map { |v| decoder.test(v).map { |c| just(c) } }
              .get_or_else { ok(nothing) }
          end
        end
      end

      # Test that an object is a hash and has a field that passes a given decoder
      def field(key, thing, *others)
        key_decoder = is(thing, *others).map_error { |e| "Error at key `#{key}`: #{e}" }

        is(Hash)
          .and_then { Decoder.new { |u| u.key?(key) || "Expected key `#{key}` in: #{u.inspect}" } }
          .and_then { Decoder.new { |u| key_decoder.test(u.fetch(key)) } }
      end

      def make_decoder_from(thing)
        nillish = thing.nil? || thing == NilClass
        raise ReSorcery::Error::ArgumentError, "Do not use `nil`" if nillish

        case thing
        when Decoder
          thing
        when Class, Module
          Decoder.new { |n| n.is_a?(thing) || "Expected a(n) #{thing}, but got a(n) #{n.class}" }
        else
          Decoder.new { |n| n == thing || "Expected #{thing.inspect}, but got #{n.inspect}" }
        end
      end

      def test_multiple(decoders, instance)
        decoders.inject(err([])) do |error_array, decoder|
          error_array.or_else do |errors|
            decoder.test(instance).map_error { |error| errors << error }
          end
        end
      end
    end
  end
end
