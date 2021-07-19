# frozen_string_literal: true

module LinkedPayload
  module Error
    class LinkedPayloadError < StandardError; end

    class ArgumentError < LinkedPayloadError; end
  end
end
