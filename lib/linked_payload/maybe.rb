# frozen_string_literal: true

module LinkedPayload
  module Maybe
    private

    def just(value)
      LinkedPayload::Maybe::Just.new(value)
    end

    def nothing
      LinkedPayload::Maybe::Nothing.new
    end

    # If `value` is `nil`, return nothing; else, return `just(value)`
    #
    # @param value The value to wrap in a `Maybe`.
    # @return [Maybe]
    def nillable(value)
      value.nil? ? nothing : just(value)
    end
  end
end
