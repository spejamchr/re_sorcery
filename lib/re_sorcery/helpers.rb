module ReSorcery
  module Helpers
    private

    def just(value)
      Maybe::Just.new(value)
    end

    def nothing
      Maybe::Nothing.new
    end

    # Wrap a possibly-nil value in a `Maybe`
    #
    # @param value The value to wrap in a `Maybe`.
    # @return [Maybe]
    def nillable(value)
      value.nil? ? nothing : just(value)
    end

    def ok(value)
      Result::Ok.new(value)
    end

    def err(e)
      Result::Err.new(e)
    end
  end
end
