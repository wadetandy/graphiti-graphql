module Graphiti
  module Graphql
    class Schema
      GRAPHQL_SCALAR_TYPE_MAP = {
        string: ::GraphQL::Types::String,
        integer_id: ::GraphQL::Types::ID,
        integer: ::GraphQL::Types::Int,
        float: ::GraphQL::Types::Float,
        boolean: ::GraphQL::Types::Boolean,
        datetime: ::GraphQL::Types::ISO8601DateTime,
      }

      attr_reader :query_entrypoints, :raw_blocks

      def initialize
        @query_entrypoints = {}
        @raw_blocks = []
      end

      def add_entrypoint(query, resource, singular)
        @query_entrypoints[query.to_sym] = {
          resource: resource,
          singular: singular
        }
      end

      def add_raw_block(block)
        @raw_blocks.push(block)
      end

      def generate_schema
        query_type = build_query_type
        raw = raw_blocks

        Class.new(GraphQL::Schema) do
          query(query_type)

          raw.each do |block|
            instance_eval(&block)
          end
        end
      end

      private

      def type_for_resource(resource)
        GraphQL::ObjectType.define do
          name resource.type.to_s.camelize
          description "A #{resource.type.to_s.singularize}"

          resource.all_attributes.each_pair do |att, details|
            if details[:readable]
              field att, types.String
            end
          end
        end
      end

      def resource_types
        return @resource_types if @resource_types
        @resource_types = {}

        query_entrypoints.each_pair do |entry, details|
          resource = details[:resource]
          @resource_types[resource.type] ||= type_for_resource(resource)
        end

        @resource_types
      end

      def build_query_type
        types_hash = resource_types
        queries = query_entrypoints

        @query ||= GraphQL::ObjectType.define do
          name "Query"

          queries.each_pair do |query_field, details|
            resource = details[:resource]
            singular = details[:singular]
            type_info = types_hash[resource.type]
            name = resource.type.to_s.underscore

            if singular
              field query_field do
                type type_info
                argument :id, !types.ID
                resolve ->(obj, args, ctx) {
                  Graphiti.with_context(ctx) do
                    resource.find(id: args[:id]).data
                  end
                }
              end
            else
              field query_field do
                type types[type_info]

                filter_map = {}
                resource.filters.each_pair do |att, details|
                  details[:operators].each do |operator|
                    filter_name = "#{att}_#{operator.first}"
                    filter_map[filter_name] = [att, operator.first]
                    argument filter_name, GRAPHQL_SCALAR_TYPE_MAP[details[:type]]
                  end
                end

                resolve ->(obj, args, ctx) {
                  params = {}

                  args.keys.each do |arg|
                    val = args[arg]
                    params[:filter] ||= {}

                    filter, operator = filter_map[arg]

                    params[:filter][filter] ||= {}
                    params[:filter][filter][operator] = val
                  end

                  Graphiti.with_context(ctx) do
                    resource.all(params).data
                  end
                }
              end
            end
          end
        end
      end
    end
  end
end