# frozen_string_literal: true

require "uri"
require "addressable/uri"

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

        def valid_rels
          ReSorcery.configuration.fetch(:link_rels)
        end

        def valid_methods
          ReSorcery.configuration.fetch(:link_methods)
        end

        def uri_able
          is(URI, Addressable::URI).or_else do
            is(String).and_then do
              Decoder.new do |u|
                ok(Addressable::URI.parse(u))
              rescue Addressable::URI::InvalidURIError
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
          default_method = ReSorcery.configuration.fetch(:default_link_method).call(valid_methods)
          default_type = ReSorcery.configuration.fetch(:default_link_type)

          [
            [:rel, rel_decoder, -> { @args[:rel] }],
            [:href, uri_able, -> { @args[:href] }],
            [:method, method_decoder, -> { @args.fetch(:method, default_method) }],
            [:type, String, -> { @args.fetch(:type, default_type) }],
          ]
        end
      end
    end
  end
end
