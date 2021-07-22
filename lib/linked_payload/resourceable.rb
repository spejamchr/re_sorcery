module LinkedPayload
  module Resourceable
    include Result
    include Fielded
    include Linked

    def resource
      ok({})
        .assign(:payload) { fields }
        .assign(:links) { links }
    end

    def as_json(*)
      resource.as_json
    end
  end
end
