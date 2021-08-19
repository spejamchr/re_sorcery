# frozen_string_literal: true

module ReSorcery
  module Linked
    class LinkClassFactory
      extend Decoder::BuiltinDecoders

      def self.valid_rels
        ReSorcery.configuration.fetch(
          :link_rels,
          %w[
            self
            create
            update
            destroy
          ],
        )
      end

      def self.valid_methods
        ReSorcery.configuration.fetch(
          :link_methods,
          %w[
            get
            post
            patch
            put
            delete
          ],
        )
      end

      URI_ABLE = is(String, URI).and do |s|
        next true if s.is_a?(URI)

        begin
          ok(URI.parse(s))
        rescue URI::InvalidURIError
          err("Not a valid URI: #{s}")
        end
      end

      def self.make_link_class
        default_method = valid_methods.first
        this = self

        Class.new do
          include Fielded

          def initialize(args)
            @args = args
          end

          field :rel, is(*this.valid_rels), -> { @args[:rel] }
          field :href, URI_ABLE, -> { @args[:href] }
          field :method, is(*this.valid_methods), -> { @args.fetch(:method, default_method) }
          field :type, String, -> { @args.fetch(:type, 'application/json') }
        end
      end
    end
  end
end
