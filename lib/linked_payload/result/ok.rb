# frozen_string_literal: true

module LinkedPayload
  module Result
    class Ok
      include Result
      include LinkedPayload::Error::ArgCheck

      class NonHashAssignError < LinkedPayload::Error::LinkedPayloadError
        def initialize(value)
          @value = value
        end

        def message
          "Result#assign can only be used when the @value is a Hash, but was a(n) #{@value.class}"
        end
      end

      def initialize(value)
        @value = value
      end

      def and_then(&block)
        arg_check('block', block.call(@value), Result)
      end

      def map(&block)
        ok(block.call(@value))
      end

      def map_error
        self
      end

      def or_else
        self
      end

      def assign(name, &block)
        raise NonHashAssignError, @value unless @value.is_a?(Hash)

        arg_check('block', block.call(@value), Result)
          .map { |k| @value.merge(name => k) }
      end

      def ==(other)
        other.class == Result::Ok && other.instance_eval { @value } == @value
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
