# frozen_string_literal: true

module ReSorcery
  class Checker
    # Common checkers implemented here for convenience
    module BuiltinCheckers
      include Helpers

      private

      # Check that an object is a thing (or one of a list of things)
      #
      # Convenience method for creating common types of `Checker`s.
      #
      # @param [Checker|Class|Module|unknown] at_least_one_thing
      # @param [Array<Checker|Class|Module|unknown>] other_things
      #
      # Accepts any number of arguments greater than 1. Call the list of
      # arguments `things`.
      #
      # For each argument `thing` in `things`:
      #
      # - If `thing` is a Checker, return it unchanged.
      # - If `thing` is a Class or Module, create a Checker that checks whether
      #   an object `is_a?(thing)`.
      # - Otherwise, create a Checker that checks if an object equals `thing`
      #   (using `==`).
      #
      # Then create a checker that tests each of these checkers one by one
      # against a given item until one passes or they have all failed.
      #
      # @return [Checker]
      def is(at_least_one_thing, *other_things)
        things = [at_least_one_thing] + other_things
        checkers = things.map { |t| make_checker_from(t) }

        Checker.new do |instance|
          check_multiple(checkers, instance).map_error do |errors|
            errors.count == 1 ? errors[0] : "all checkers in `is` failed: (#{errors.join(' | ')})"
          end
        end
      end

      # Check that an object is an array of objects that pass the checker `is(thing)`
      #
      # @param at_least_one_thing @see `is` for details
      # @param other_things @see `is` for details
      # @return [Checker]
      def array(at_least_one_thing, *other_things)
        checker = is(at_least_one_thing, *other_things)
        Checker.new do |instance|
          is(Array).check(instance).and_then do |arr|
            arr.each_with_index.inject(ok([])) do |result_array, (unknown, index)|
              result_array.and_then do |ok_array|
                checker.check(unknown)
                  .map { |checked| ok_array << checked }
                  .map_error { |error| "Error at index `#{index}` of Array: #{error}" }
              end
            end
          end
        end
      end

      # Check that an object is a Maybe whose `value` passes some `Checker`
      #
      # @param at_least_one_thing @see `is` for details
      # @param other_things @see `is` for details
      # @return [Checker]
      def maybe(at_least_one_thing, *other_things)
        checker = is(at_least_one_thing, *other_things)
        Checker.new do |instance|
          is(Maybe::Just, Maybe::Nothing).check(instance).and_then do |maybe|
            maybe
              .map { |v| checker.check(v).map { |c| just(c) } }
              .get_or_else { ok(nothing) }
          end
        end
      end

      def make_checker_from(thing)
        nillish = thing.nil? || thing == NilClass
        raise ReSorcery::Error::ArgumentError, "Do not use `nil`" if nillish

        case thing
        when Checker
          thing
        when Class, Module
          Checker.new { |n| n.is_a?(thing) || "Expected a(n) #{thing}, but got a(n) #{n.class}" }
        else
          Checker.new { |n| n == thing || "Expected #{thing.inspect}, but got #{n.inspect}" }
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
  end
end
