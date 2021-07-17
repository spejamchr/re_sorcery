# frozen_string_literal: true

require 'linked_payload/checked'
require 'linked_payload/checker/builtin_checkers'
require 'linked_payload/error'
require 'linked_payload/linked'
require 'linked_payload/result'
require 'linked_payload/version'

module LinkedPayload
  include Checked
  include Linked
  include Result

  def self.included(base)
    base.extend Checked::ClassMethods
    base.extend Linked::ClassMethods
    base.extend Checker::BuiltinCheckers
  end

  def resource
    ok({})
      .assign(:payload) { checked }
      .assign(:links) { links }
      .as_json
  end

  def as_json(*)
    resource
  end
end
