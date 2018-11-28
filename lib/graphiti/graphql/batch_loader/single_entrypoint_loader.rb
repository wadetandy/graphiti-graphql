module Graphiti::Graphql::BatchLoader
  class SingleEntrypointLoader < BaseLoader
    def perform(_)
      super([OpenStruct.new])
    end

    def assign(_, records)
      fulfill(:entry, records.first)
    end
  end
end