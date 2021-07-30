# frozen_string_literal: true

require 'linked_payload/version'
require 'linked_payload/error'
require 'linked_payload/arg_check'
require 'linked_payload/maybe'
require 'linked_payload/result'
require 'linked_payload/checker'
require 'linked_payload/fielded'
require 'linked_payload/maybe/just'
require 'linked_payload/maybe/nothing'
require 'linked_payload/linked'

module LinkedPayload
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
