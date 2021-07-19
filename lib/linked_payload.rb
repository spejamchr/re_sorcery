# frozen_string_literal: true

require 'linked_payload/fielded'
require 'linked_payload/checker/builtin_checkers'
require 'linked_payload/error'
require 'linked_payload/linked'
require 'linked_payload/result'
require 'linked_payload/version'

module LinkedPayload
  include Fielded
  include Linked
  include Result

  def self.included(base)
    base.extend Fielded::ClassMethods
    base.extend Linked::ClassMethods
    base.extend Checker::BuiltinCheckers
  end

  def resource
    ok({})
      .assign(:payload) { fields }
      .assign(:links) { links }
      .as_json
  end

  def as_json(*)
    resource
  end
end
