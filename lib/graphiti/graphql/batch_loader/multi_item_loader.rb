module Graphiti::Graphql::BatchLoader
  class MultiItemLoader < BaseLoader
    def assign(parent_records, records)
      map = records.group_by(&sideload.foreign_key)

      parent_records.each do |parent_record|
        if sideload.type == :has_many
          matching_records = map[parent_record.send(sideload.primary_key)] || []
        else
          matching_records = sideload.assign_each(parent_record, records)
        end
        fulfill(parent_record, matching_records)
      end
    end
  end
end