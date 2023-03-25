# frozen_string_literal: true

require "test_helper"

module ReSorcery
  class FieldedTest < Minitest::Test
    include Helpers

    def self.test_in_class(&block)
      Class.new do
        include Fielded
        instance_exec(&block)
      end
    end

    StringField = test_in_class { field :a, is(String), -> { "string" } }
    NumberField = test_in_class { field :b, Numeric, -> { 0 } }
    NestedField = test_in_class { field :sf, StringField, -> { StringField.new } }
    TrilyNested = test_in_class { field :nf, NestedField, -> { NestedField.new } }
    ArrayNested = test_in_class { field :sfs, array(StringField), -> { [StringField.new] * 2 } }

    class InheritedStringField < StringField
      field :c, String, -> { "other string" }
    end

    class OverwrittenStringField < StringField
      field :a, String, -> { "new string" }
    end

    ArrayOfStringOrNumber = test_in_class do
      field :c, array(is(StringField, NumberField)), -> { [StringField.new, NumberField.new] }
    end

    BrokenString = test_in_class { field :broken, String, -> { 0 } }

    def test_not_maybe
      refute_kind_of Maybe, StringField.new
    end

    def test_not_result
      refute_kind_of Result, StringField.new
    end

    def test_string_field
      assert_equal ok(a: "string"), StringField.new.fields
    end

    def test_inherited_string_field
      assert_equal ok(a: "string", c: "other string"), InheritedStringField.new.fields
    end

    def test_overwritten_string_field
      assert_equal ok(a: "new string"), OverwrittenStringField.new.fields
    end

    def test_fields_for_something_nestedly_fielded
      assert_equal ok(nf: { sf: { a: "string" } }), TrilyNested.new.fields
    end

    def test_fields_for_something_array_nested
      assert_equal ok(sfs: [{ a: 'string' }, { a: 'string' }]), ArrayNested.new.fields
    end

    def test_fields_for_is_nested
      assert_equal ok(c: [{ a: 'string' }, { b: 0 }]), ArrayOfStringOrNumber.new.fields
    end

    def test_fields_for_broken
      assert_kind_of Result::Err, BrokenString.new.fields
    end

    def test_nil_cannot_be_returned_in_a_field
      assert_raises(ReSorcery::Error::ReSorceryError) do
        Class.new do
          include Fielded
          field :nil, is(nil), -> { nil }
        end
      end
    end

    class BlocklessForm
      include Fielded
      field :name, String
      def name
        "Albert"
      end
    end

    def test_blockless_form_of_field
      assert_equal ok(name: "Albert"), BlocklessForm.new.fields
    end

    class InvalidBlocklessForm
      include Fielded
      field :name, String
      def name
        :Albert
      end
    end

    def test_invalid_blockless_form_of_field
      assert_kind_of Result::Err, InvalidBlocklessForm.new.fields
    end

    UndefinedBlocklessForm = test_in_class { field :name, String }

    def test_undefined_blockless_form_of_field
      assert_raises(NoMethodError) { UndefinedBlocklessForm.new.fields }
    end
  end
end
