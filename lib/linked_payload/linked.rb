# frozen_string_literal: true

require 'linked_payload/linked/link'

module LinkedPayload
  module Linked
    include LinkedPayload::Result

    module ClassMethods
      include LinkedPayload::Error::ArgCheck
      attr_reader :links_proc

      # Define a set of `Link`s for a class
      #
      # The block is evaluated in the context of an instance of the class, so
      # the set of `Link`s can be contextualized. For example, if the current
      # user doesn't have permissions to edit the object, the "update" `Link`
      # can be left out:
      #
      #     class MyObject
      #       include Linked
      #       attr_reader :id, :current_user
      #
      #       def initialize(id, current_user)
      #         @id = id
      #         @current_user = current_user
      #       end
      #
      #       links do
      #         link 'self', "/my_objects/#{id}"
      #         link 'update', "/my_objects/#{id}", 'put' if current_user.can_update?(self)
      #         link 'destroy', "/my_objects/#{id}", 'delete' if current_user.can_destroy?(self)
      #       end
      #     end
      #
      # The block is not cached.
      def links(&block)
        @links_proc = block
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    # Define a `Link` for an object
    def link(rel, href, method = 'get', type = 'application/json')
      (@_created_links ||= []) << Link.new(rel: rel, href: href, method: method, type: type).fields
    end

    def links
      instance_exec(&self.class.links_proc)
      created_links = (@_created_links ||= [])
      @_created_links = [] # Clear out so `links` can run cleanly next time

      created_links.each_with_index.inject(ok([])) do |result_array, (link_result, index)|
        result_array.and_then do |ok_array|
          link_result
            .map { |link| ok_array << link }
            .map_error { |error| "Error with Link at index #{index}: #{error}" }
        end
      end
    end
  end
end
