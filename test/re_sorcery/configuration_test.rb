# frozen_string_literal: true

require "test_helper"

module ReSorcery
  class ConfigurationTest
    def setup
      teardown
      ReSorcery::Linked.instance_exec { @link_class = nil }
    end

    def teardown
      ReSorcery::Linked.instance_exec { @link_class = nil }
      ReSorcery.instance_exec { @configuration = @configured = nil }
    end

    def test_cannot_configure_after_including_re_sorcery
      Class.new { include ReSorcery }

      assert_raises(Error::InvalidConfigurationError) do
        ReSorcery.configure { raise "This shouldn't run" }
      end
    end

    def test_cannot_configure_twice
      ReSorcery.configure {}

      assert_raises(Error::InvalidConfigurationError) do
        ReSorcery.configure { raise "This shouldn't run" }
      end
    end
  end
end
