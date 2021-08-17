# frozen_string_literal: true

module ReSorcery
  module Error
    class ReSorceryError < StandardError; end

    class ArgumentError < ReSorceryError; end

    class NonHashAssignError < ReSorceryError
      def initialize(value)
        @value = value
      end

      def message
        "#assign can only be used when the @value is a Hash, but was a(n) #{@value.class}"
      end
    end

    class InvalidConfigurationError < ReSorceryError
      def initialize(details)
        @details = details
      end

      def message
        "ReSorcery can only be configured once, and only before `include`ing ReSorcery, but was " +
          @details
      end
    end
  end
end
