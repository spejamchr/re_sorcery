# frozen_string_literal: true

require "uri"

module ReSorcery
  module Linked
    class LinkClassFactory
      class << self
        include Decoder::BuiltinDecoders

        def make_link_class
          fields = build_fields

          Class.new do
            include Fielded

            def initialize(args)
              @args = args
            end

            fields.each { |(name, decoder, value)| field name, decoder, value }
          end
        end

        private

        def default_rels
          %w[
            self
            create
            update
            destroy
          ]
        end

        def valid_rels
          ReSorcery.configuration.fetch(:link_rels, default_rels)
        end

        def default_methods
          %w[
            get
            post
            patch
            put
            delete
          ]
        end

        def valid_methods
          ReSorcery.configuration.fetch(:link_methods, default_methods)
        end

        def uri_able
          is(URI).or_else do
            is(String).and_then do
              Decoder.new do |u|
                ok(URI.parse(u))
              rescue URI::InvalidURIError
                err("Not a valid URI: #{u}")
              end
            end
          end
        end

        def str_or_sym
          is(String, Symbol).map(&:to_s)
        end

        def rel_decoder
          str_or_sym.and_then { |v| Decoder.new { is(*valid_rels).test(v) } }
        end

        def method_decoder
          str_or_sym.and_then { |v| Decoder.new { is(*valid_methods).test(v) } }
        end

        def build_fields
          default_method = valid_methods.first

          [
            [:rel, rel_decoder, -> { @args[:rel] }],
            [:href, uri_able, -> { @args[:href] }],
            [:method, method_decoder, -> { @args.fetch(:method, default_method) }],
            [:type, String, -> { @args.fetch(:type, 'application/json') }],
          ]
        end
      end
    end
  end
end
