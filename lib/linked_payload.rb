# frozen_string_literal: true

require 'linked_payload/fielded'
require 'linked_payload/linked'
require 'linked_payload/result'
require 'linked_payload/version'

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
