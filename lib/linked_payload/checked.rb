# frozen_string_literal: true

require 'linked_payload/error'
require 'linked_payload/result'

module LinkedPayload
  module Checked
    include Result

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
    def checked
      (self.class.fields || []).inject(ok({})) do |result_hash, (name, field_hash)|
        result_hash.and_then do |ok_hash|
          field_hash[:type].check(instance_exec(&field_hash[:pro]))
            .map { |checked| ok_hash.merge(name => checked) }
            .map_error { |error| "Error at field `#{name}` of `#{self.class}`: #{error}" }
        end
      end
    end
  end
end
