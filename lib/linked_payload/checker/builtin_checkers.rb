# frozen_string_literal: true

require 'linked_payload/checker'
require 'linked_payload/result'

module LinkedPayload
  class Checker
    # Common checkers implemented here for convenience
    module BuiltinCheckers
      include Result

      # Check that an object is a thing
      #
      # @see `LinkedPayload::Checker.is` for details
      def is(thing)
        Checker.is(thing)
      end

      # Check that an object is one of several possibilities
      #
      #     string_bool = one_of('yes', 'no')
      #     string_bool.check('yes') #=> ok('yes')
      #     string_bool.check('other') #=> an Err
      #
      # Each item in the argument `things` is transformed into a `Checker` using `is`.
      # @see `LinkedPayload::Checker.is` for details
      def one_of(*things)
        checkers = things.map { |thing| is(thing) }

        Checker.new do |instance|
          all_errors = checkers.inject(err([])) do |error_array, checker|
            error_array.or_else do |errors|
              checker.check(instance).map_error { |error| errors << error }
            end
          end
          all_errors.map_error { |errors| "one_of failed: (#{errors.join(', ')})" }
        end
      end

      # Check that an object is an array of of objects that pass the checker `is(thing)`
      #
      # @see `LinkedPayload::Checker.is` for details
      def array(thing)
        checker = is(thing)
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
    end
  end
end
