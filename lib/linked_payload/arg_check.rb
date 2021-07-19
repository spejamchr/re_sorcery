# frozen_string_literal: true

require 'linked_payload/error'

module LinkedPayload
  module ArgCheck
    def self.arg_check(name, value, *types)
      return value if types.any? { |t| value.is_a?(t) }

      fn = caller_locations.first.label
      s = "`##{fn}` expected `#{name}` to be #{types.join(' or ')}; but got #{value.class}"
      raise LinkedPayload::Error::ArgumentError, s
    end
  end
  private_constant :ArgCheck
end
