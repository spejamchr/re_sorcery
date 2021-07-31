# frozen_string_literal: true

require 're_sorcery/version'
require 're_sorcery/error'
require 're_sorcery/arg_check'
require 're_sorcery/maybe'
require 're_sorcery/result'
require 're_sorcery/checker'
require 're_sorcery/fielded'
require 're_sorcery/maybe/just'
require 're_sorcery/maybe/nothing'
require 're_sorcery/linked'

module ReSorcery
  include Fielded
  include Linked

  def self.included(base)
    base.extend Fielded::ClassMethods
    base.extend Linked::ClassMethods
  end

  def self.prepended(base)
    included(base)
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
