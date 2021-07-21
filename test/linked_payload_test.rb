# frozen_string_literal: true

require "test_helper"

class LinkedPayloadTest < Minitest::Test
  include LinkedPayload::Result

  def test_that_it_has_a_version_number
    refute_nil ::LinkedPayload::VERSION
  end

  class StaticResource
    include LinkedPayload
    field :string, String, -> { "string" }
    field :number, is(Numeric), -> { 42 }
    links do
      link 'self', '/here'
      link 'create', '/here', 'post'
    end
  end

  CORRECT_STATIC_RESOURCE_AS_JSON = {
    kind: :ok,
    value: {
      payload: { string: "string", number: 42 },
      links: [
        { rel: 'self', href: '/here', method: 'get', type: 'application/json' },
        { rel: 'create', href: '/here', method: 'post', type: 'application/json' },
      ],
    },
  }.freeze

  def test_simple_linked_payload
    assert_equal CORRECT_STATIC_RESOURCE_AS_JSON, StaticResource.new.as_json
  end

  class DynamicPayload
    include LinkedPayload
    def initialize(value)
      @value = value
    end
    field :value, String, -> { @value }
  end

  def correct_dynamic_payload_as_json(value)
    { kind: :ok, value: { payload: { value: value }, links: [] } }
  end

  class DynamicLink
    include LinkedPayload
    def initialize(href)
      @href = href
    end
    links do
      link 'self', @href
    end
  end

  def correct_dynamic_link_as_json(href)
    {
      kind: :ok,
      value: {
        payload: {},
        links: [{ rel: 'self', href: href, method: 'get', type: 'application/json' }],
      },
    }
  end

  def test_valid_dynamic_payload
    value = "Some string here"
    assert_equal correct_dynamic_payload_as_json(value), DynamicPayload.new(value).as_json
  end

  def test_invalid_dynamic_payload
    value = :symbols_are_not_strings
    assert_equal :err, DynamicPayload.new(value).as_json[:kind]
  end

  def test_valid_dynamic_link
    value = "/link"
    assert_equal correct_dynamic_link_as_json(value), DynamicLink.new(value).as_json
  end

  def test_invalid_dynamic_link
    value = :symbols_are_not_strings
    assert_equal :err, DynamicLink.new(value).as_json[:kind]
  end
end
