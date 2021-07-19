# frozen_string_literal: true

require 'linked_payload/fielded'
require 'linked_payload/checker/builtin_checkers'

module LinkedPayload
  module Linked
    class Link
      include Fielded
      extend Checker::BuiltinCheckers

      VALID_REL = %w[
        self
        create
        update
        destroy
      ].yield_self { |arr| one_of(*arr) }
      private_constant :VALID_REL

      VALID_METHOD = %w[
        get
        post
        patch
        put
        delete
      ].yield_self { |arr| one_of(*arr) }
      private_constant :VALID_METHOD

      def initialize(args)
        @args = args
      end

      field :rel, VALID_REL, -> { @args[:rel] }
      field :href, String, -> { @args[:href] }
      field :method, VALID_METHOD, -> { @args.fetch(:method, 'get') }
      field :type, String, -> { @args.fetch(:type, 'application/json') }
    end
  end
end
