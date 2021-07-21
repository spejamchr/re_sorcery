# frozen_string_literal: true

require 'linked_payload/checker'
require 'linked_payload/result'

module LinkedPayload
  class Checker
    # Common checkers implemented here for convenience
    module BuiltinCheckers
      include Result

      # Check that an object is a thing (or one of a list of things)
      #
      # @see `LinkedPayload::Checker.is` for details
      def is(*things)
        Checker.is(*things)
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
