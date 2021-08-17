# frozen_string_literal: true

module ReSorcery
  # Configure `ReSorcery`: All configuration kept in one place
  #
  # `ReSorcery` has some values that can be configured by users. To keep such
  # configuration clear, `#configure` can only be called once.
  #
  # Also, `#configure` must be called before using `ReSorcery`
  #
  # @see `Configuration::CONFIGURABLES` for a list of what can be configured and
  # what value each configurable takes.
  #
  # Example:
  #
  #     ReSorcery.configure do
  #       link_rels ['self', 'create', 'update']
  #       link_methods ['get', 'post', 'put']
  #     end
  #
  module Configuration
    extend Decoder::BuiltinDecoders

    # def self.extended(base)
    #   included = base.method(:included)
    #   base.define_instance_method(:included) do |included_base|
    #     @configured = true
    #     included.call(included_base)
    #   end
    # end

    CONFIGURABLES = {
      link_rels: array(String),
      link_methods: array(String),
    }.freeze

    def configuration
      @configuration ||= {}
    end

    def configure(&block)
      raise Error::InvalidConfigurationError, @configured if configured?

      @configured = "configured at #{caller_locations.first}"
      instance_exec(&block)
    end

    private

    def configured?
      @configured ||= false
    end

    CONFIGURABLES.each do |name, decoder|
      define_method(name) do |value|
        decoder.test(value).cata(
          ok: ->(v) { configuration[name] = v },
          err: ->(e) { raise Error::ArgumentError, "Error configuring `#{name}`: #{e}" },
        )
      end
    end
  end
end
