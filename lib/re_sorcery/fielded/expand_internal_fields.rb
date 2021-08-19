# frozen_string_literal: true

module ReSorcery
  module Fielded
    module ExpandInternalFields
      extend Helpers

      # Used internally to expand deeply nested `Fielded` structures
      #
      # `Hash` is intentionally *not* expanded. Create a `Fielded` class instead.
      #
      # Similarly, `nil` is intentionally rejected here. Use a type that more
      # meaningfully represents an empty value instead.
      def self.expand(obj)
        case obj
        when ReSorcery
          obj.resource
        when Fielded
          obj.fields
        when Linked
          obj.links
        when String, Numeric, Symbol, TrueClass, FalseClass
          ok(obj)
        when Array
          expand_for_array(obj)
        when URI
          ok(obj.to_s)
        when Hash
          err("`Hash` cannot be safely expanded as a `field`. Use a `Fielded` class instead.")
        when NilClass
          err("`nil` cannot be returned as a `field`")
        else
          err("Cannot deeply expand fields of class #{obj.class}")
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
