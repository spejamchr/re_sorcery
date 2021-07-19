# frozen_string_literal: true

require "test_helper"

module LinkedPayload
  class FieldedTest < Minitest::Test
    include LinkedPayload::Result

    class StringField
      include Fielded
      extend Checker::BuiltinCheckers
      field :a, is(String), -> { "string" }
    end

    class NumberField
      include Fielded
      extend Checker::BuiltinCheckers
      field :b, is(Numeric), -> { 0 }
    end

    class NestedField
      include Fielded
      extend Checker::BuiltinCheckers
      field :sf, is(StringField), -> { StringField.new }
    end

    class TriplyNested
      include Fielded
      extend Checker::BuiltinCheckers
      field :nf, is(NestedField), -> { NestedField.new }
    end

    class ArrayNested
      include Fielded
      extend Checker::BuiltinCheckers
      field :sfs, array(StringField), -> { [StringField.new, StringField.new] }
    end

    class ArrayOfStringOrNumber
      include Fielded
      extend Checker::BuiltinCheckers
      field :c, array(one_of(StringField, NumberField)), -> { [StringField.new, NumberField.new] }
    end

    class BrokenString
      include Fielded
      extend Checker::BuiltinCheckers
      field :broken, is(String), -> { 0 }
    end

    def test_deeply_fielded_for_something_fielded
      fielded = StringField.new
      assert_equal ok(a: "string"), Fielded.deeply_fielded(fielded)
    end

    def test_deeply_fielded_simple_types
      objects = ['string', 1, 1.1, 1i, 1r, :symbol, true, false]
      objects.each do |thing|
        assert_equal ok(thing), Fielded.deeply_fielded(thing)
      end
    end

    def test_deeply_fielded_array
      assert_equal(
        ok(['string', 1, :symbol, true, false, { a: 'string' }]),
        Fielded.deeply_fielded(['string', 1, :symbol, true, false, StringField.new]),
      )
    end

    def test_fields_for_something_nestedly_fielded
      assert_equal ok(nf: { sf: { a: "string" } }), TriplyNested.new.fields
    end

    def test_fields_for_something_array_nested
      assert_equal ok(sfs: [{ a: 'string' }, { a: 'string' }]), ArrayNested.new.fields
    end

    def test_fields_for_one_of_nested
      assert_equal ok(c: [{ a: 'string' }, { b: 0 }]), ArrayOfStringOrNumber.new.fields
    end

    def test_fields_for_broken
      assert_kind_of Err, BrokenString.new.fields
    end

    def test_nil_cannot_be_returned_in_a_field
      assert_raises(LinkedPayload::Error::LinkedPayloadError) do
        Class.new do
          include Fielded
          extend Checker::BuiltinCheckers
          field :nil, is(nil), -> { nil }
        end
      end
    end
  end
end
