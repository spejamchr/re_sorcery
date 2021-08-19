# ReSorcery

> *Create resources with run-time payload type checking and link validation*

Frontend clients can decode and type check `JSON` responses from their backends using packages like
[Elm's Decoders] or [`jsonous` for TypeScript].

[Elm's Decoders]: https://package.elm-lang.org/packages/elm/json/latest/Json-Decode
[`jsonous` for TypeScript]: https://github.com/kofno/festive-possum/tree/main/packages/jsonous

This is a similar package for the backend, so that Ruby can perform run-time payload type checking
and link validation before sending resources to the client.

- A `<resource>` is a `Hash` with a `:payload` field (a `Hash`) and a `:links` field (an
  `Array` of `<link>` objects).
- Each entry in the `:payload` is type checked using a `Decoder` (inspired by [Elm's Decoders]).
- A `<link>` is a `Hash` with four fields:
  - `:href`, which is either a `URI` or a `String` that parses as a valid `URI`;
  - `:rel`, which is a white-listed `String`;
  - `:method`, which is also a white-listed `String`; and
  - `:type`, which is a `String`.

Demo:

```ruby
class StaticResource
  include ReSorcery
  field :string, is(String), -> { "a string" }
  field :number, is(Numeric), -> { 42 }
  links do
    link 'self', '/here'
    link 'create', '/here', 'post'
  end
end

StaticResource.new.resource
# #<ReSorcery::Result::Ok @value={
#   :payload=>{:string=>"a string", :number=>42},
#   :links=>[{:rel=>"self", :href=>"/here", :method=>"get", :type=>"application/json"},
#            {:rel=>"create", :href=>"/here", :method=>"post", :type=>"application/json"}]
# }>
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 're_sorcery'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install re_sorcery

## Usage

```ruby
class User
  include ReSorcery

  def initialize(**args)
    @args = args
  end

  def admin?
    @args[:admin] == true
  end

  field :name, String, -> { @args[:name] }
  field :id, is(Integer).and { |i| i.positive? || '`id` must be positive' }, -> { @args[:id] }
  field :admin?, is(true, false)

  links do
    link 'self', "/users/#{@args[:id]}"
    link 'destroy', "/users/#{@args[:id]}", 'delete' unless admin? # Don't delete admins
  end
end

User.new(name: :Invalid, id: 1).as_json #=> {
#   :kind=>:err,
#   :value=>"Error at field `name` of `User`: Expected a(n) String, but got a(n) Symbol"
# }
User.new(name: "Spencer", id: 1).as_json #=> {
#   :kind=>:ok,
#   :value=>{
#     :payload=>{
#       :name=>"Spencer",
#       :id=>1,
#       :spencer?=>true
#     },
#     :links=>[
#       {:rel=>"self", :href=>"/users/1", :method=>"get", :type=>"application/json"}
#     ]
#   }
# }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run
the tests. You can also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new
version, update the version number in `version.rb`, and then run `bundle exec rake release`, which
will create a git tag for the version, push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/spejamchr/re_sorcery.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
