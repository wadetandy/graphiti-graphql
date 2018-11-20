module Graphiti
  module Graphql
    class Schema
      attr_reader :query_entrypoints

      def initialize
        @query_entrypoints = {}
      end

      def add_entrypoint(query, resource, singular)
        @query_entrypoints[query.to_sym] = {
          resource: resource,
          singular: singular
        }
      end

      def generate_schema
        query_type = build_query_type

        schema = Class.new(GraphQL::Schema) do
          query(query_type)

          if block
            instance_eval(&block)
          end
        end
      end

      private

      def build_query_type(entry_points)
        types_hash = types
        entry = entry_points

        @query ||= GraphQL::ObjectType.define do
          name "Query"

          entry.each do |resource|
            type_info = types_hash[resource.type]
            name = resource.type.to_s.underscore

            gql_type_map = {
              string: types.String,
              integer_id: types.ID,
              integer: types.Int,
              float: types.Float,
              boolean: types.Boolean,
              datetime: GraphQL::Types::ISO8601DateTime,
            }

            field name.singularize do
              type type_info
              argument :id, !types.ID
              resolve ->(obj, args, ctx) {
                Graphiti.with_context(ctx) do
                  resource.find(id: args[:id]).data
                end
              }
            end

            field name.pluralize do
              type types[type_info]

              filter_map = {}
              resource.filters.each_pair do |att, details|
                details[:operators].each do |operator|
                  filter_name = "#{att}_#{operator.first}"
                  filter_map[filter_name] = [att, operator.first]
                  argument filter_name, gql_type_map[details[:type]]
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

      def types
        @types ||= begin
          types_map = {}
          entry_points.each do |resource|
            types_map[resource.type] = GraphQL::ObjectType.define do
              name resource.type.to_s.camelize
              description "A #{resource.type.to_s.singularize}"

              resource.attributes.merge(resource.extra_attributes).each_pair do |att, details|
                if details[:readable]
                  field att, types.String
                end
              end

              # resource.sideloads.

              # field :name, !types.String
              # field :genre, types.String
              # field :albums, types[Types::AlbumType]

              # field :yearsActive, types.String do
              #   resolve ->(obj, args, ctx) {
              #     "Active: " + obj.year_active_start.to_s + "-" + obj.year_active_end.to_s
              #   }
              # end
            end
          end

          types_map
        rescue => exception
          nil
        end

      end
    end
  end
end