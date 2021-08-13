# frozen_string_literal: true

module ReSorcery
  module Maybe
    class Just
      include Fielded

      field :kind, :just, -> { :just }
      field :value, Decoder.new { true }, -> { @value }

      def initialize(value)
        @value = value
      end

      def and_then(&block)
        ArgCheck['block', block.call(@value), Just, Nothing]
      end

      def map(&block)
        Just.new(block.call(@value))
      end

      def or_else
        self
      end

      def get_or_else
        @value
      end

      def assign(name, &block)
        raise Error::NonHashAssignError, @value unless @value.is_a?(Hash)

        ArgCheck['block', block.call(@value), Just, Nothing]
          .map { |k| @value.merge(name => k) }
      end

      def ==(other)
        other.class == Just && other.instance_eval { @value } == @value
      end

      def as_json(*)
        {
          kind: :just,
          value: @value,
        }
      end
    end
  end
end
