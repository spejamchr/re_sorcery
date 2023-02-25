# frozen_string_literal: true

require 're_sorcery/fielded/expand_internal_fields'

module ReSorcery
  module Fielded
    include Helpers

    module ClassMethods
      include Decoder::BuiltinDecoders

      private

      # Set a field for instances of a class
      #
      # There is intentionally no way to make fields optionally nil. Use a type
      # that more meaningfully represents an empty value instead, such as a
      # `Maybe` type or discriminated unions.
      #
      # @param [Symbol] name
      # @param [arg of Decoder.is] type @see `ReSorcery::Decoder.is` for details
      # @param [Proc] pro: in the context of an instance of the class, return the value of the field
      def field(name, type, pro = -> { send(name) })
        ArgCheck['name', name, Symbol]
        ArgCheck['pro', pro, Proc]

        (@fields ||= {})[name] = { type: is(type), pro: pro }
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    # Returns the `Decoder#test`ed fields of the object, wrapped in a `Result`
    #
    # If all the `Decoder`s pass, this will return an `Ok`. If any of them
    # fail, it will return an `Err` instead.
    #
    # @return [Result<String, Hash>]
    def fields
      self.class.instance_exec { @fields ||= [] }.inject(ok({})) do |result_hash, (name, field_hash)|
        result_hash.assign(name) do
          field_hash[:type].test(instance_exec(&field_hash[:pro]))
            .and_then { |tested| ExpandInternalFields.expand(tested) }
            .map_error { |error| "Error at field `#{name}` of `#{self.class}`: #{error}" }
        end
      end
    end
  end
end
