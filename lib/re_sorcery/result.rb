# frozen_string_literal: true

require 're_sorcery/result/ok'
require 're_sorcery/result/err'

module ReSorcery
  module Result
    private

    def ok(value)
      Ok.new(value)
    end

    def err(e)
      Err.new(e)
    end
  end
end
