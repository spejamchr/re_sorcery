# frozen_string_literal: true

module LinkedPayload
  module Error
    class LinkedPayloadError < StandardError; end

    class ArgumentError < LinkedPayloadError; end

    class NonHashAssignError < LinkedPayloadError
      def initialize(value)
        @value = value
      end

      def message
        "#assign can only be used when the @value is a Hash, but was a(n) #{@value.class}"
      end
    end

  end
end
