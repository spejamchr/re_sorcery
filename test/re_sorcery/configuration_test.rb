# frozen_string_literal: true

require "test_helper"

module ReSorcery
  class ConfigurationTest < Minitest::Test
    def setup
      clear_re_sorcery_config
    end

    def teardown
      clear_re_sorcery_config
    end

    ReSorcery::Configuration::CONFIGURABLES.each do |k, v|
      define_method("test_#{k}_configuration_default_is_valid") do
        default = v.fetch(:default)
        decoder = v.fetch(:decoder)
        assert_equal Result::Ok.new(default), decoder.test(default)
      end
    end

    def test_cannot_configure_after_including_re_sorcery
      Class.new { include ReSorcery }

      assert_raises(Error::InvalidConfigurationError) do
        ReSorcery.configure { raise "This shouldn't run" }
      end
    end

    def test_cannot_configure_twice
      ReSorcery.configure { "do nothing" }

      assert_raises(Error::InvalidConfigurationError) do
        ReSorcery.configure { raise "This shouldn't run" }
      end
    end

    def test_configurables_are_frozen
      conf = ReSorcery::Configuration::CONFIGURABLES
      pre = "Expected CONFIGURABLES"
      assert conf.frozen?, "#{pre} to be frozen"
      conf.each do |k, v|
        assert k.frozen?, "#{pre} key #{k.inspect} to be frozen"
        assert v.frozen?, "#{pre}[#{k.inspect}] to be frozen"
        v.each do |vk, vv|
          assert vk.frozen?, "#{pre}[#{k.inspect}] key #{vk.inspect} to be frozen"
          assert vv.frozen?, "#{pre}[#{k.inspect}] value for #{vk.inspect} to be frozen"
        end
      end
    end
  end
end
