# frozen_string_literal: true

require 're_sorcery/checker/builtin_checkers'

module ReSorcery
  # Check that an object satisfies some property
  #
  # A `Checker` represents a piece of logic for verifying some property. A
  # simple example would be a `Checker` that verifies that an object
  # `is_a?(String)`. A `ReSorcery::Result` is used to represent the result
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
    include ReSorcery::Result

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
      end.and_then { |r| r.nil? ? err("`nil` was returned on a successful check!") : ok(r) }
    end
  end
end
