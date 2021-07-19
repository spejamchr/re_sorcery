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
  class Checker
    include LinkedPayload::Result

    # Convenience method for creating common types of `Checker`s
    #
    # @param [Checker|Class|Module|unknown] thing
    # When `thing` is a Checker, return it unchanged. When `thing` is a Class
    # or Module, create a Checker that checks whether an object `is_a?(thing)`.
    # Otherwise, create a Checker that checks if an object equals `thing`
    # (`==`).
    #
    # @return [Checker]
    def self.is(thing)
      return thing if thing.is_a?(Checker)

      if thing.is_a?(Class) || thing.is_a?(Module)
        new { |n| n.is_a?(thing) || "Expected a(n) #{thing}, but got a(n) #{n.class}" }
      else
        new { |n| n == thing || "Expected #{thing.inspect}, but got #{n.inspect}" }
      end
    end

    def initialize(&block)
      @block = block
    end

    # Check that an `unknown` object satisfies some property
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
      end
    end
  end
end
