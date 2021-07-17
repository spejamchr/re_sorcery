# frozen_string_literal: true

module LinkedPayload
  module Error
    class LinkedPayloadError < StandardError; end

    class ArgumentError < LinkedPayloadError; end

    module ArgCheck
      def arg_check(name, value, *types)
        return if types.any? { |t| value.is_a?(t) }

        fn = caller_locations.first.label
        s = "#{fn} expected  `#{name}` to be #{types.join(', or')}; but got #{value.class}"
        raise ArgumentError, s
      end
    end
  end
end
