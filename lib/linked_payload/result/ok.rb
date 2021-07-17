# frozen_string_literal: true

module LinkedPayload
  module Result
    class Ok
      include Result

      def initialize(value)
        @value = value
      end

      def and_then(&block)
        result = block.call(@value)
        case result
        when Result::Ok, Result::Err
          result
        else
          raise "block in Result::Ok#and_then must return Result, but returned #{result.class}"
        end
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
        raise "Assign can only be used on results with values of Hashes" unless @value.is_a?(Hash)

        result = block.call(@value)
        case result
        when Result::Ok, Result::Err
          result.map { |k| @value.merge(name => k) }
        else
          raise "block in Result::Ok#assign must return Result, but returned #{result.class}"
        end
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
