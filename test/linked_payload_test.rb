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
    prepend LinkedPayload
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

  def test_invalid_dynamic_payload_included
    value = :symbols_are_not_strings
    assert_equal :err, DynamicPayload.new(value).as_json[:kind]
  end

  def test_valid_dynamic_link
    value = "/link"
    assert_equal correct_dynamic_link_as_json(value), DynamicLink.new(value).as_json
  end

  def test_invalid_dynamic_link_prepended
    value = :symbols_are_not_strings
    assert_equal :err, DynamicLink.new(value).as_json[:kind]
  end

  class Empty
    include LinkedPayload
  end

  def test_empty_linked_payload_works_fine
    assert_equal ok(payload: {}, links: []), Empty.new.resource
  end

  class Child
    include LinkedPayload
    attr_reader :id, :name
    def initialize(id, name)
      @id = id
      @name = name
    end
    field :id, Numeric, -> { id }
    field :name, String, -> { name }
    links { link 'self', "/children/#{id}" }
  end

  class ParentChildren
    include LinkedPayload
    attr_reader :parent, :children
    def initialize(parent, children)
      @parent = parent
      @children = children
    end
    field :children, array(Child), -> { children }
    links { link 'self', "parents/#{parent.id}/children" }
  end

  class Parent
    include LinkedPayload
    attr_reader :id, :name, :children
    def initialize(id, name, children)
      @id = id
      @name = name
      @children = children
    end
    field :id, Numeric, -> { id }
    field :name, String, -> { name }
    field :parent_children, ParentChildren, -> { ParentChildren.new(self, children) }
    links { link 'self', "/parents/#{id}" }
  end

  def test_nested_resources
    thing1 = Child.new(1, 'thing1')
    thing2 = Child.new(2, 'thing2')
    the_cat_in_the_hat = Parent.new(1, 'The Cat in the Hat', [thing1, thing2])
    correct = {
      kind: :ok,
      value: {
        payload: {
          id: 1,
          name: "The Cat in the Hat",
          parent_children: {
            payload: {
              children: [
                {
                  payload: { id: 1, name: "thing1" },
                  links: [
                    { rel: "self", href: "/children/1", method: "get", type: "application/json" },
                  ],
                },
                {
                  payload: { id: 2, name: "thing2" },
                  links: [
                    { rel: "self", href: "/children/2", method: "get", type: "application/json" },
                  ],
                },
              ],
            },
            links: [
              { rel: "self", href: "parents/1/children", method: "get", type: "application/json" },
            ],
          },
        },
        links: [{ rel: "self", href: "/parents/1", method: "get", type: "application/json" }],
      },
    }
    assert_equal correct, the_cat_in_the_hat.as_json
    assert_equal 'thing1', the_cat_in_the_hat.as_json.dig(:value, :payload, :parent_children, :payload, :children, 0, :payload, :name)
    assert_equal 'self', the_cat_in_the_hat.as_json.dig(:value, :payload, :parent_children, :payload, :children, 0, :links, 0, :rel)
  end
end
