# frozen_string_literal: true

require 'linked_payload/arg_check'

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
        ArgCheck.arg_check('block', block.call(@err), Result)
      end

      def assign(_name)
        self
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
    end
  end
end
