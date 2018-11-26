module Graphiti::Graphql::BatchLoader
  class BaseLoader < ::GraphQL::Batch::Loader
    def initialize(resource, filter_attribute, context: {})
      @resource = resource
      @filter_attribute = filter_attribute
      @context = context
    end
  end
end