# frozen_string_literal: true

require 're_sorcery/decoder/builtin_decoders'

module ReSorcery
  # Check that an object satisfies some property
  #
  # A `Decoder` represents a piece of logic for verifying some property. A
  # simple example would be a `Decoder` that verifies that an object
  # `is_a?(String)`. A `ReSorcery::Result` is used to represent the result
  # of the logic. This can be created like:
  #
  #     is_string =
  #       Decoder.new { |n| n.is_a?(String) ? ok(n) : err("Expected String, got #{n.class}") }
  #
  # And then used like:
  #
  #     is_string.check("I'm a string") #=> ok("I'm a string")
  #     is_string.check(:symbol) #=> err("Expected String, got Symbol")
  #
  # Because returning the original object wrapped in `ok` is the common result
  # when a `Decoder` passes, a shorthand in the initializer is to return
  # `true`, and `Decoder` will wrap the object for you.
  #
  #     is_string =
  #       Decoder.new { |n| n.is_a?(String) || err("Expected String, got #{n.class}") }
  #
  # A similar shorthand: Since the alternative is always something wrapped in
  # `err`, if anything but `true` or a `Result` is returned, it will be wrapped
  # in `err`.
  #
  #     is_string =
  #       Decoder.new { |n| n.is_a?(String) || "Expected String, got #{n.class}" }
  #
  # All three of these implementations of `is_string` are equivalent.
  #
  # Note that this library has strong opinions against using `nil`, so `nil`
  # will never pass `check`.
  #
  class Decoder
    include Helpers

    def initialize(&block)
      @block = block
    end

    # Use the decoder to check that an `unknown` object satisfies some property
    #
    # Note that `ok(nil)` will never be returned.
    #
    # @param [unknown] unknown
    # @return [Result]
    def check(unknown)
      result = @block.call(unknown)
      case result
      when Result::Ok, Result::Err
        result
      when TrueClass
        ok(unknown)
      else
        err(result)
      end.and_then { |r| r.nil? ? err("`nil` was returned on a successful check!") : ok(r) }
    end

    # Apply some block within the context of a successful decoder
    def map(&block)
      Decoder.new { |unknown| check(unknown).map(&block) }
    end

    # Apply some block within the context of an unsuccessful decoder
    def map_error(&block)
      Decoder.new { |unknown| check(unknown).map_error(&block) }
    end

    # Chain decoders
    #
    # The second decoder can be chosen based on the (successful) result of the
    # first decoder.
    #
    # The block must return a `Decoder`.
    def and_then(&block)
      Decoder.new do |unknown|
        check(unknown).and_then do |v|
          ArgCheck['block.call(value)', block.call(v), Decoder].check(unknown)
        end
      end
    end

    # Chain decoders like and_then, but use the chain to build an object
    def assign(key, other)
      ArgCheck['key', key, Symbol]
      ArgCheck['other', other, Proc, Decoder]
      other = ->(_) { other.call } if other.is_a?(Proc) && other.arity.zero?

      and_then do |a|
        ArgCheck['decoded value', a, Hash]

        decoder = other.is_a?(Decoder) ? other : ArgCheck['other.call', other.call(a), Decoder]
        decoder.map { |b| a.merge(key => b) }
      end
    end
  end
end
