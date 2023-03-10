# frozen_string_literal: true

module ReSorcery
  # Configure `ReSorcery`: All configuration kept in one place
  #
  # `ReSorcery` has some values that can be configured by users. To keep such
  # configuration clear, and to prevent confusing behavior, `#configure` can
  # only be called once, and must be called before `include`ing `ReSorcery`.
  #
  # Example:
  #
  #     ReSorcery.configure do
  #       link_rels ['self', 'create', 'update']
  #       link_methods ['get', 'post', 'put']
  #     end
  #
  # @see `Configuration::CONFIGURABLES`, whose keys define the list of
  # configuration methods. Each entry contains a `:decoder` key, which is used
  # to check the value passed to the configuration method, and a `:default`
  # key, which is the default value for that entry.
  #
  module Configuration
    extend Decoder::BuiltinDecoders

    UNIQUE_STRING_OR_SYMBOL = non_empty_array(is(String, Symbol).map(&:to_s)).map(&:uniq)
    DEFAULT_LINK_METHOD_DECODER = is(Proc)
      .and { |p| p.arity == 1 || "default_link_method Proc must accept exactly one argument" }

    CONFIGURABLES = {
      link_rels: {
        decoder: UNIQUE_STRING_OR_SYMBOL,
        default: %w[self create update destroy].freeze,
      }.freeze,
      link_methods: {
        decoder: UNIQUE_STRING_OR_SYMBOL,
        default: %w[get post patch put delete].freeze,
      }.freeze,
      default_link_method: {
        decoder: DEFAULT_LINK_METHOD_DECODER,
        default: ->(link_methods) { link_methods.first }.freeze,
      }.freeze,
      default_link_type: {
        decoder: is(String),
        default: "application/json",
      }.freeze,
    }.freeze

    def configuration
      @configuration ||= CONFIGURABLES.transform_values { |v| v.fetch(:default) }
    end

    def configure(&)
      raise Error::InvalidConfigurationError, @configured if configured?

      @configured = "configured at #{caller_locations.first}"
      instance_exec(&)
    end

    private

    def configured?
      @configured ||= false
    end

    CONFIGURABLES.each do |name, metadata|
      decoder = metadata.fetch(:decoder)
      define_method(name) do |value|
        decoder.test(value).cata(
          ok: ->(v) { configuration[name] = v },
          err: ->(e) { raise Error::ArgumentError, "Error configuring `#{name}`: #{e}" },
        )
      end
    end
  end
end
