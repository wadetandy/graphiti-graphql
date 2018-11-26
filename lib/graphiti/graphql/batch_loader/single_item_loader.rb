module Graphiti::Graphql::BatchLoader
  class SingleItemLoader < BaseLoader
    def perform(ids)
      Graphiti.with_context(@context) do
        records = @resource.all({@filter_attribute => ids}).data

        records.each { |record| fulfill(record.id, record) }
        # If a record wasnt found, fulfill with nil:
        ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
      end
    end
  end
end