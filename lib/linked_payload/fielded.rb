# frozen_string_literal: true

require 'linked_payload/fielded/expand_internal_fields'

module LinkedPayload
  module Fielded
    include Result
    include Maybe
    include LinkedPayload::Checker::BuiltinCheckers

    module ClassMethods
      include Checker::BuiltinCheckers

      private

      # Set a field for instances of a class
      #
      # There is intentionally no way to make fields optionally nil. Use a type
      # that more meaningfully represents an empty value instead, such as a
      # `Maybe` type or discriminated unions.
      #
      # @param [Symbol] name
      # @param [arg of Checker.is] type @see `LinkedPayload::Checker.is` for details
      # @param [Proc] pro: in the context of an instance of the class, return the value of the field
      def field(name, type, pro)
        ArgCheck.arg_check('name', name, Symbol)
        ArgCheck.arg_check('pro', pro, Proc)

        (@fields ||= {})[name] = { type: is(type), pro: pro }
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    # Returns the *checked* fields of the object, wrapped in a `Result`
    #
    # If all the `Checker`s pass, this will return an `Ok`. If any of them
    # fail, it will return an `Err` instead.
    #
    # @return [Result<String, Hash>]
    def fields
      self.class.instance_exec { @fields ||= [] }.inject(ok({})) do |result_hash, (name, field_hash)|
        result_hash.and_then do |ok_hash|
          field_hash[:type].check(instance_exec(&field_hash[:pro]))
            .and_then { |checked| ExpandInternalFields.expand(checked) }
            .map { |fielded| ok_hash.merge(name => fielded) }
            .map_error { |error| "Error at field `#{name}` of `#{self.class}`: #{error}" }
        end
      end
    end
  end
end
