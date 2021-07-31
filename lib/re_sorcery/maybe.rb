# frozen_string_literal: true

module ReSorcery
  module Maybe
    private

    def just(value)
      Just.new(value)
    end

    def nothing
      Nothing.new
    end

    # Wrap a possibly-nil value in a `Maybe`
    #
    # @param value The value to wrap in a `Maybe`.
    # @return [Maybe]
    def nillable(value)
      value.nil? ? nothing : just(value)
    end
  end
end
