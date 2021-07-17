# frozen_string_literal: true

module LinkedPayload
  module Result
    class Err
      include Result

      def initialize(err)
        @err = err
      end

      def and_then
        self
      end

      def map
        self
      end

      def map_error(&block)
        err(block.call(@err))
      end

      def or_else(&block)
        result = block.call(@err)
        case result
        when Result::Ok, Result::Err
          result
        else
          raise "block in Result::Err#or_else must return Result, but returned #{result.class}"
        end
      end

      def ==(other)
        other.class == Result::Err && other.instance_eval { @err } == @err
      end

      def as_json(*)
        {
          kind: :err,
          value: @err,
        }
      end

      def assign(_name)
        self
      end
    end
  end
end
