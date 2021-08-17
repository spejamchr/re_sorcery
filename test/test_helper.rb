# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "re_sorcery"

def re_sorceried_klass(&block)
  Class.new do
    include ReSorcery
    instance_exec(&block)
  end
end

# Assert that a value at some path in json is equal to an expected value
#
# @param [any] expected What you expect to find in the json at the path
# @param [Array|Hash] json The json-link object
# @path [Array] path The dig-like path to the location of interest
def assert_at_json(expected, json, path)
  klass = path.first.is_a?(Integer) ? Array : Hash
  assert_kind_of klass, json
  (1...path.count).each do |count|
    klass = path[count].is_a?(Integer) ? Array : Hash
    assert_kind_of klass, json.dig(*path.first(count))
  end
  assert_equal expected, json.dig(*path)
end

require "minitest/autorun"
