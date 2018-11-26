module Graphiti::Graphql::BatchLoader
  class MultiItemLoader < BaseLoader
    def perform(ids)
      Graphiti.with_context(@context) do
        records = @resource.all({@filter_attribute => ids}).data

        ids.each do |id|
          matching_records = records.select { |r| id == (r.send(@filter_attribute)) }
          fulfill(id, matching_records)
        end
      end
    end
  end
end