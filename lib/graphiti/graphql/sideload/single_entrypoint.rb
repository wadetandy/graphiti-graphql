module Graphiti::Graphql::Sideload
  class SingleEntrypoint < Graphiti::Sideload::HasOne
    def query_entrypoint
      true
    end
  end
end