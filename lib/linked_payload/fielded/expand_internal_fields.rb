# frozen_string_literal: true

require 'linked_payload/result'

module LinkedPayload
  module Fielded
    module ExpandInternalFields
      extend LinkedPayload::Result

      # Used internally to check deeply nested `Fielded` structures
      #
      # `Hash` is intentionally *not* expanded. Create a `Fielded` class instead.
      #
      # Similarly, `nil` is intentionally rejected here. Use a type that more
      # meaningfully represents an empty value instead.
      def self.expand(obj)
        case obj
        when Fielded
          obj.fields
        when String, Numeric, Symbol, TrueClass, FalseClass
          ok(obj)
        when Array
          expand_for_array(obj)
        when NilClass
          err("`nil` cannot be returned as a `field`")
        else
          err("Cannot deeply check #{obj.class}")
        end
      end

      def self.expand_for_array(array)
        array.each_with_index.inject(ok([])) do |result_array, (element, index)|
          result_array.and_then do |ok_array|
            expand(element)
              .map { |good| ok_array << good }
              .map_error { |error| "Error at index `#{index}` of Array: #{error}" }
          end
        end
      end
    end
    private_constant :ExpandInternalFields
  end
end
