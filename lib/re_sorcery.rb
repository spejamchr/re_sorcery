# frozen_string_literal: true

require 're_sorcery/version'
require 're_sorcery/error'
require 're_sorcery/arg_check'
require 're_sorcery/maybe'
require 're_sorcery/result'
require 're_sorcery/helpers'
require 're_sorcery/decoder'
require 're_sorcery/fielded'
require 're_sorcery/maybe/just'
require 're_sorcery/maybe/nothing'
require 're_sorcery/linked'
require 're_sorcery/configuration'

module ReSorcery
  include Fielded
  include Linked
  include Helpers
  extend Configuration

  def self.included(base)
    base.extend Fielded::ClassMethods
    base.extend Linked::ClassMethods
    @configured = "included at #{caller_locations.first}"
  end

  def resource
    Result::Ok.new({})
      .assign(:payload) { fields }
      .assign(:links) { links }
  end

  def as_json(*)
    resource.as_json
  end
end
