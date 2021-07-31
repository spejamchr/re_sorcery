# frozen_string_literal: true

module ReSorcery
  module Linked
    class Link
      include Fielded

      VALID_REL = %w[
        self
        create
        update
        destroy
      ].yield_self { |arr| is(*arr) }
      private_constant :VALID_REL

      VALID_METHOD = %w[
        get
        post
        patch
        put
        delete
      ].yield_self { |arr| is(*arr) }
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
