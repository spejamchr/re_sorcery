# frozen_string_literal: true

module ReSorcery
  module Result
    class Err
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
        Err.new(block.call(@err))
      end

      def or_else(&block)
        ArgCheck['block', block.call(@err), Ok, Err]
      end

      def assign(_name)
        self
      end

      def ==(other)
        other.class == Err && other.instance_eval { @err } == @err
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
