module Graphiti::Graphql::BatchLoader
  class SingleItemLoader < BaseLoader
    def assign(parent_records, records)
      map = records.group_by(&sideload.foreign_key)

      parent_records.each do |parent_record|
        matching = map[parent_record.send(sideload.primary_key)] || []
        fulfill(parent_record, matching.first)
      end
    end
  end
end