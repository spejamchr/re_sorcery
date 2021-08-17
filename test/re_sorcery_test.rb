# frozen_string_literal: true

require "test_helper"

class ReSorceryTest < Minitest::Test
  include ReSorcery::Helpers

  def test_that_it_has_a_version_number
    refute_nil ::ReSorcery::VERSION
  end

  class StaticResource
    include ReSorcery
    field :string, maybe(maybe(String)), -> { just(just("string")) }
    field :number, is(Numeric), -> { 42 }
    links do
      link 'self', '/here'
      link 'create', '/here', 'post'
    end
  end

  CORRECT_STATIC_RESOURCE_AS_JSON = {
    kind: :ok,
    value: {
      payload: { string: { kind: :just, value: { kind: :just, value: "string" } }, number: 42 },
      links: [
        { rel: 'self', href: '/here', method: 'get', type: 'application/json' },
        { rel: 'create', href: '/here', method: 'post', type: 'application/json' },
      ],
    },
  }.freeze

  def test_simple_re_sorcery
    assert_equal CORRECT_STATIC_RESOURCE_AS_JSON, StaticResource.new.as_json
  end

  class DynamicPayload
    include ReSorcery
    def initialize(value)
      @value = value
    end
    field :value, String, -> { @value }
  end

  def correct_dynamic_payload_as_json(value)
    { kind: :ok, value: { payload: { value: value }, links: [] } }
  end

  class DynamicLink
    include ReSorcery
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

  class Empty
    include ReSorcery
  end

  def test_empty_re_sorcery_works_fine
    assert_equal ok(payload: {}, links: []), Empty.new.resource
  end

  def test_empty_not_maybe
    refute_kind_of ReSorcery::Maybe, Empty.new
  end

  def test_empty_not_result
    refute_kind_of ReSorcery::Result, Empty.new
  end

  class Child
    include ReSorcery
    attr_reader :id, :name
    def initialize(id, name)
      @id = id
      @name = name
    end
    field :id, Numeric
    field :name, String
    links { link 'self', "/children/#{id}" }
  end

  class ParentChildren
    include ReSorcery
    attr_reader :parent, :children
    def initialize(parent, children)
      @parent = parent
      @children = children
    end
    field :children, array(Child)
    links { link 'self', "parents/#{parent.id}/children" }
  end

  class Parent
    include ReSorcery
    attr_reader :id, :name, :children
    def initialize(id, name, children)
      @id = id
      @name = name
      @children = children
    end
    field :id, Numeric
    field :name, String
    field :parent_children, ParentChildren, -> { ParentChildren.new(self, children) }
    links { link 'self', "/parents/#{id}" }
  end

  def test_nested_resources
    thing1 = Child.new(1, 'thing1')
    thing2 = Child.new(2, 'thing2')
    parent = Parent.new(1, 'The Cat in the Hat', [thing1, thing2]).as_json

    child = parent.dig(:value, :payload, :parent_children, :payload, :children, 0) || {}

    assert_equal 'The Cat in the Hat', parent.dig(:value, :payload, :name)
    assert_equal '/parents/1', parent.dig(:value, :links, 0, :href)
    assert_equal 'thing1', child.dig(:payload, :name)
    assert_equal 'self', child.dig(:links, 0, :rel)
    assert_equal '/children/1', child.dig(:links, 0, :href)
  end
end
