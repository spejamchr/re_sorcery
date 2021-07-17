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

    def self.is(klass)
      class_or_module = klass.is_a?(Class) || klass.is_a?(Module)
      return klass if klass.is_a?(Checker)
      raise "expected Checker, Class, or Module, but got #{klass.class}" unless class_or_module

      new { |n| n.is_a?(klass) ? ok(n) : err("Expected #{klass}, but got #{n.class}") }
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
