# frozen_string_literal: true

module ReSorcery
  module ArgCheck
    def self.[](name, value, *types)
      return value if types.any? { |t| value.is_a?(t) }

      fn = caller_locations.first.label
      s = "`#{fn}` expected `#{name}` to be #{types.join(' or ')}; but got #{value.class}: #{value.inspect}"
      raise ReSorcery::Error::ArgumentError, s
    end
  end
  private_constant :ArgCheck
end
