# frozen_string_literal: true

require 'linked_payload/arg_check'

module LinkedPayload
  module Maybe
    class Nothing
      include Maybe

      def and_then
        self
      end

      def map
        self
      end

      def or_else(&block)
        ArgCheck.arg_check('block', block.call, Maybe)
      end

      def get_or_else(&block)
        block.call
      end

      def assign(_name)
        self
      end

      def ==(other)
        other.class == Maybe::Nothing
      end

      def as_json(*)
        {
          kind: :nothing,
        }
      end
    end
  end
end
