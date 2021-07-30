# frozen_string_literal: true

require 'linked_payload/maybe/just'
require 'linked_payload/maybe/nothing'

module LinkedPayload
  module Maybe
    private

    def just(value)
      LinkedPayload::Maybe::Just.new(value)
    end

    def nothing
      LinkedPayload::Maybe::Nothing.new
    end
  end
end
