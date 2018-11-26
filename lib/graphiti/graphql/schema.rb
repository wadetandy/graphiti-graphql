module Graphiti
  module Graphql
    class Schema
      attr_reader :query_entrypoints, :raw_blocks

      def initialize(base_type)
        @query_entrypoints = {}
        @raw_blocks = []
        @base_type = base_type
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

          use ::GraphQL::Batch
        end
      end

      private

      def build_query_type
        type_generator = TypeGenerator.new(@base_type)
        queries = query_entrypoints

        queries.each_pair do |_, details|
          resource = details[:resource]
          type_generator.add_resource(resource)
        end

        type_generator.finalize

        @query ||= GraphQL::ObjectType.define do
          name "Query"

          queries.each_pair do |query_field, details|
            resource = details[:resource]
            singular = details[:singular]
            type_info = type_generator[resource.type]
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
                    argument filter_name, TypeGenerator::GRAPHQL_SCALAR_TYPE_MAP[details[:type]]
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