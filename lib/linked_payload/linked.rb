# frozen_string_literal: true

require 'linked_payload/linked/link'

module LinkedPayload
  module Linked
    include LinkedPayload::Result

    module ClassMethods
      include LinkedPayload::Error::ArgCheck
      attr_reader :link_procs

      def link(link_maker)
        (@link_procs ||= []) << arg_check('link_maker', link_maker, Proc)
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def links
      bad_val = lambda do |index, value|
        err("Expected link_maker at index #{index} to return Hash or nil, but got #{value.class}")
      end

      (self.class.link_procs || []).each_with_index.inject(ok([])) do |result_array, (pro, index)|
        result_array.and_then do |ok_array|
          value = instance_exec(&pro)
          next result_array if value.nil?
          next bad_val.call(index, value) unless value.is_a?(Hash)

          Link.new(value).fields
            .map { |link| ok_array << link }
            .map_error { |error| "Error with Link at index #{index}: #{error}" }
        end
      end
    end
  end
end
