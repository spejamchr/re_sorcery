# frozen_string_literal: true

require 'linked_payload/checked'
require 'linked_payload/checker/builtin_checkers'

module LinkedPayload
  module Linked
    class Link
      include Checked
      extend Checker::BuiltinCheckers

      VALID_REL = %w[
        self
        create
        update
        destroy
      ].map { |s| eql(s) }.yield_self { |arr| one_of(arr) }
      private_constant :VALID_REL

      VALID_METHOD = %w[
        get
        post
        patch
        put
        delete
      ].map { |s| eql(s) }.yield_self { |arr| one_of(arr) }
      private_constant :VALID_METHOD

      def initialize(args)
        @args = args
      end

      field :rel, VALID_REL, -> { @args[:rel] }
      field :href, string, -> { @args[:href] }
      field :method, VALID_METHOD, -> { @args.fetch(:method, 'get') }
      field :type, string, -> { @args.fetch(:type, 'application/json') }
    end

    private_constant :Link
  end
end
