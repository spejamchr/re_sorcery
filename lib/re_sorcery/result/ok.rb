# frozen_string_literal: true

module ReSorcery
  module Result
    class Ok
      class << self
        def new(value)
          return Result::Err.new("`nil` was provided as a succeful result value!") if value.nil?

          super
        end
      end

      def initialize(value)
        @value = value
      end

      def and_then(&block)
        ArgCheck['block', block.call(@value), Ok, Err]
      end

      def map(&block)
        Ok.new(block.call(@value))
      end

      def map_error
        self
      end

      def or_else
        self
      end

      def assign(name, &block)
        raise Error::NonHashAssignError, @value unless @value.is_a?(Hash)

        ArgCheck['block', block.call(@value), Ok, Err]
          .map { |k| @value.merge(name => k) }
      end

      def cata(ok:, err:)
        ok.call(@value)
      end

      def ==(other)
        other.class == Ok && other.instance_eval { @value } == @value
      end

      def as_json(*)
        {
          kind: :ok,
          value: @value,
        }
      end
    end
  end
end
