# frozen_string_literal: true

module ReSorcery
  module Maybe
    class Nothing
      include Fielded

      field :kind, :nothing, -> { :nothing }

      def and_then
        self
      end

      def map
        self
      end

      def or_else(&block)
        ArgCheck.arg_check('block', block.call, Just, Nothing)
      end

      def get_or_else(&block)
        block.call
      end

      def assign(_name)
        self
      end

      def ==(other)
        other.class == Nothing
      end

      def as_json(*)
        {
          kind: :nothing,
        }
      end
    end
  end
end
