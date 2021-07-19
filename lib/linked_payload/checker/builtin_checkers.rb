# frozen_string_literal: true

require 'linked_payload/checker'
require 'linked_payload/result'

module LinkedPayload
  class Checker
    module BuiltinCheckers
      include Result

      def string
        Checker.is(String)
      end

      def numeric
        Checker.is(Numeric)
      end

      def eql(thing)
        Checker.new do |unknown|
          unknown == thing ? ok(unknown) : err("Expected #{thing.inspect}, but received #{unknown.inspect}")
        end
      end

      def one_of(*things)
        checkers = things.map { |thing| Checker.is(thing) }

        Checker.new do |instance|
          all_errors = checkers.inject(err([])) do |error_array, checker|
            error_array.or_else do |errors|
              checker.check(instance).map_error { |error| errors << error }
            end
          end
          all_errors.map_error { |errors| "one_of failed: (#{errors.join(', ')})" }
        end
      end

      def array(thing)
        checker = Checker.is(thing)
        Checker.new do |instance|
          Checker.is(Array)
            .check(instance)
            .and_then do |arr|
              arr.each_with_index.inject(ok([])) do |result_array, (unknown, index)|
                result_array.and_then do |ok_array|
                  checker
                    .check(unknown)
                    .and_then { |checkable| Checker.checked(checkable) }
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
