# frozen_string_literal: true

require 'linked_payload/result/ok'
require 'linked_payload/result/err'

module LinkedPayload
  module Result
    private

    def ok(value)
      LinkedPayload::Result::Ok.new(value)
    end

    def err(e)
      LinkedPayload::Result::Err.new(e)
    end
  end
end
