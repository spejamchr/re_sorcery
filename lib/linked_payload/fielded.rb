# frozen_string_literal: true

require 'linked_payload/error'
require 'linked_payload/result'

module LinkedPayload
  module Fielded
    include Result

    class << self
      include LinkedPayload::Result

      # Used internally to check deeply nested `Fielded` structures
      #
      # `Hash` is intentionally *not* `deeply_fielded`. Create a `Fielded` class instead.
      #
      # Similarly, `nil` is intentionally *not* `deeply_fielded`. Don't use it.
      def deeply_fielded(obj)
        case obj
        when Fielded
          obj.fields
        when String, Numeric, Symbol, TrueClass, FalseClass
          ok(obj)
        when Array
          deeply_fielded_array(obj)
        else
          err("Cannot deeply check #{obj.class}")
        end
      end

      private

      def deeply_fielded_array(array)
        array.each_with_index.inject(ok([])) do |result_array, (element, index)|
          result_array.and_then do |ok_array|
            deeply_fielded(element)
              .map { |good| ok_array << good }
              .map_error { |error| "Error at index `#{index}` of Array: #{error}" }
          end
        end
      end
    end

    module ClassMethods
      include Error::ArgCheck

      attr_reader :fields

      # @param [Symbol] name
      # @param [Checker] type
      # @param [Proc] pro: in the context of an instance of the class, return the value of the field
      def field(name, type, pro)
        arg_check('name', name, Symbol)
        arg_check('type', type, Checker)
        arg_check('pro', pro, Proc)

        (@fields ||= {})[name] = { type: type, pro: pro }
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    # @return [Result<String, Hash>]
    def fields
      (self.class.fields || []).inject(ok({})) do |result_hash, (name, field_hash)|
        result_hash.and_then do |ok_hash|
          field_hash[:type].check(instance_exec(&field_hash[:pro]))
            .and_then { |checked| Fielded.deeply_fielded(checked) }
            .map { |fielded| ok_hash.merge(name => fielded) }
            .map_error { |error| "Error at field `#{name}` of `#{self.class}`: #{error}" }
        end
      end
    end
  end
end
