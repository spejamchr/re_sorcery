# frozen_string_literal: true

require 'linked_payload/fielded'
require 'linked_payload/checker'
require 'linked_payload/checker/builtin_checkers'
require 'linked_payload/error'
require 'linked_payload/linked'
require 'linked_payload/result'
require 'linked_payload/version'
require 'linked_payload/resourceable'

module LinkedPayload
  include Resourceable

  module ClassMethods
    def try_new(*args)
      instance = new(*args)
      instance.resource.map { instance }
    end

    def new(*args)
      instance = super(*args)
      instance.resource.map { instance }.map_error { |e| raise Error::ArgumentError, e }
      instance
    end
  end

  def self.included(base)
    base.extend Fielded::ClassMethods
    base.extend Linked::ClassMethods
    base.extend Checker::BuiltinCheckers
    base.extend ClassMethods
  end

  def self.prepended(base)
    included(base)
  end
end
