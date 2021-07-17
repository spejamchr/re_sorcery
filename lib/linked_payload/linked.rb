# frozen_string_literal: true

require 'linked_payload/linked/link'

module LinkedPayload
  module Linked
    module ClassMethods
      attr_reader :links

      def link(pro)
        raise "link expected `pro` to be Proc, but got #{pro.class}" unless pro.is_a?(Proc)

        (@links ||= []) << pro
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def links
      (self.class.links || []).each_with_index.inject(ok([])) do |result_array, (pro, index)|
        result_array.and_then do |ok_array|
          result = instance_exec(&pro)
          next result_array if result.nil?
          next err("Expected link Proc at index #{index} to return Hash or nil, but got #{result.class}") unless result.is_a?(Hash)

          Link.new(result).checked
            .map { |link| ok_array << link }
            .map_error { |error| "Error with link at index #{index}: #{error}" }
        end
      end
    end
  end
end
