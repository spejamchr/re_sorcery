# frozen_string_literal: true

require 'linked_payload/result'
require 'linked_payload/checked'

module LinkedPayload
  class Checker
    include LinkedPayload::Result

    class << self
      include LinkedPayload::Result

      def checked(obj)
        case obj
        when Checker, Checked
          obj.checked
        when String, Numeric, Symbol, TrueClass, FalseClass
          ok(obj)
        when Array
          check_array(obj)
        else
          err("Cannot check #{obj.class}")
        end
      end

      private

      def check_array(array)
        array.each_with_index.inject(ok([])) do |result_array, (element, index)|
          result_array.and_then do |ok_array|
            Checker
              .checked(element)
              .map { |good| ok_array << good }
              .map_error { |error| "Error at index `#{index}` of Array: #{error}" }
          end
        end
      end
    end

    def self.is(thing)
      return thing if thing.is_a?(Checker)

      if thing.is_a?(Class) || thing.is_a?(Module)
        new { |n| n.is_a?(thing) ? ok(n) : err("Expected a(n) #{thing}, but got a(n) #{n.class}") }
      else
        new { |n| n == thing ? ok(n) : err("Expected #{thing.inspect}, but got #{n.inspect}") }
      end
    end

    def initialize(&block)
      @block = block
    end

    # @param [unknown] unknown
    # @return [Result<String, unknown>]
    def check(unknown)
      @block.call(unknown)
    end
  end
end
