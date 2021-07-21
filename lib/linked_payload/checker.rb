# frozen_string_literal: true

require 'linked_payload/result'
require 'linked_payload/fielded'

module LinkedPayload
  # Check that an object satisfies some property
  #
  # A `Checker` represents a piece of logic for verifying some property. A
  # simple example would be a `Checker` that verifies that an object
  # `is_a?(String)`. A `LinkedPayload::Result` is used to represent the result
  # of the verification. This can be created like:
  #
  #     is_string =
  #       Checker.new { |n| n.is_a?(String) ? ok(n) : err("Expected String, got #{n.class}") }
  #
  # And then used like:
  #
  #     is_string.check("I'm a string") #=> ok("I'm a string")
  #     is_string.check(:symbol) #=> err("Expected String, got Symbol")
  #
  # Because returning the original object wrapped in `ok` is the common result
  # when a `Checker` passes, a shorthand in the initializer is to return
  # `true`, and `Checker` will wrap the object for you.
  #
  #     is_string =
  #       Checker.new { |n| n.is_a?(String) || err("Expected String, got #{n.class}") }
  #
  # A similar shorthand: Since the alternative is always something wrapped in
  # `err`, if anything but `true` or a `Result` is returned, it will be wrapped
  # in `err`.
  #
  #     is_string =
  #       Checker.new { |n| n.is_a?(String) || "Expected String, got #{n.class}" }
  #
  # All three of these implementations of `is_string` are equivalent.
  #
  # Note that this library has strong opinions against using `nil`, so `nil`
  # will never pass `check`.
  #
  class Checker
    include LinkedPayload::Result

    class << self
      include LinkedPayload::Result

      # Check that an object is a thing (or one of a list of things)
      #
      # Convenience method for creating common types of `Checker`s.
      #
      # @param [Array<Checker|Class|Module|unknown>] things
      # For each argument `thing` in `things`, if it is a Checker, return it
      # unchanged. When `thing` is a Class or Module, create a Checker that
      # checks whether an object `is_a?(thing)`. Otherwise, create a Checker
      # that checks if an object equals `thing` (using `==`).
      #
      # Then create a checker that tests each of these checkers one by one
      # against a given item until one passes or they have all failed.
      #
      # @return [Checker]
      def is(*things)
        checkers = things.map { |t| make_checker_from(t) }

        new do |instance|
          check_multiple(checkers, instance).map_error do |errors|
            errors.count == 1 ? errors[0] : "all checkers in `is` failed: (#{errors.join(', ')})"
          end
        end
      end

      private

      def make_checker_from(thing)
        nillish = thing.nil? || thing == NilClass
        raise LinkedPayload::Error::ArgumentError, "Do not use `nil`" if nillish

        case thing
        when Checker
          thing
        when Class, Module
          new { |n| n.is_a?(thing) || "Expected a(n) #{thing}, but got a(n) #{n.class}" }
        else
          new { |n| n == thing || "Expected #{thing.inspect}, but got #{n.inspect}" }
        end
      end

      def check_multiple(checkers, instance)
        checkers.inject(err([])) do |error_array, checker|
          error_array.or_else do |errors|
            checker.check(instance).map_error { |error| errors << error }
          end
        end
      end
    end

    def initialize(&block)
      @block = block
    end

    # Use the checker to check that an `unknown` object satisfies some property
    #
    # Note that `ok(nil)` will never be returned.
    #
    # @param [unknown] unknown
    # @return [Result]
    def check(unknown)
      result = @block.call(unknown)
      case result
      when Result
        result
      when TrueClass
        ok(unknown)
      else
        err(result)
      end.and_then { |r| r.nil? ? err("Do not return `nil` on a successful check!") : ok(r) }
    end
  end
end
