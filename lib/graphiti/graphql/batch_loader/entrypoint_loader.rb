module Graphiti::Graphql::BatchLoader
  class EntrypointLoader < BaseLoader
    def perform(_)
      super([OpenStruct.new])
    end

    def assign(_, records)
      result = single? ? records.first : records
      fulfill(:entry, result)
    end
  end
end