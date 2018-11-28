module Graphiti
  module Graphql
    class TypeGenerator
      GRAPHQL_SCALAR_TYPE_MAP = {
        string: ::GraphQL::Types::String,
        integer_id: ::GraphQL::Types::ID,
        integer: ::GraphQL::Types::Int,
        float: ::GraphQL::Types::Float,
        boolean: ::GraphQL::Types::Boolean,
        datetime: ::GraphQL::Types::ISO8601DateTime,
      }

      ENTRY_STRUCT = Struct.new(:id).new(:entry)

      def initialize(base_class)
        @type_map = {}
        @resource_map = {}
        @base_class = base_class
      end

      def [](type)
        @type_map[type.to_s]
      end

      def add_resource(resource_class)
        type_name = resource_class.type.to_s

        type_resources = @resource_map[type_name] ||= []
        if type_resources.include?(resource_class)
          return
        else
          type_resources.push(resource_class)
        end
        this = self

        object_type = @type_map[type_name] ||= GraphQL::ObjectType.define do
          name type_name.singularize.camelize

          description "A #{type_name.singularize}"

          resource_class.all_attributes.each_pair do |att, details|
            if details[:readable]
              field att, GRAPHQL_SCALAR_TYPE_MAP[details[:type]]
            end
          end

          resource_class.sideloads.each_pair do |sideload_name, sideload|
            next if sideload_name.in?([:notable])
            next if sideload.polymorphic_child?# || sideload_polymorphic_parent?

            instance_eval(&this.field_for_sideload(sideload))
          end
        end

        resource_class.sideloads.values.each do |sideload|
          next if sideload.resource_class.type.blank?
          add_resource(sideload.resource_class)
        end

        object_type
      end

      def finalize
      end

      def type_for_resource(resource_class)
        type_name = resource_class.type.to_s
        @type_map[type_name]
      end



      def field_for_sideload(sideload)
        is_single = sideload.single? || sideload.type.in?([:belongs_to, :has_one])
        is_entrypoint = sideload.respond_to?(:query_entrypoint) && sideload.query_entrypoint
        this = self

        if is_entrypoint
          loader = BatchLoader::EntrypointLoader
        else
          loader = is_single ? BatchLoader::SingleItemLoader : BatchLoader::MultiItemLoader
        end

        Proc.new do
          type_proc = -> {
            sideload_type = this.type_for_resource(sideload.resource_class)
            is_single ? sideload_type : types[sideload_type]
          }

          field sideload.name, type_proc do
            if is_single
              argument :id, !types.ID if is_entrypoint
            else
              filter_map = {}

              sideload.resource.filters.each_pair do |att, details|
                next if att == sideload.primary_key || att == sideload.foreign_key

                details[:operators].each do |operator|
                  filter_name = "#{att}_#{operator.first}"
                  filter_map[filter_name] = [att, operator.first]
                  argument filter_name, TypeGenerator::GRAPHQL_SCALAR_TYPE_MAP[details[:type]]
                end
              end
            end

            resolve -> (obj, args, ctx) {
              if sideload.type == :belongs_to
                attribute = sideload.primary_key
              else
                attribute = sideload.foreign_key
              end

              params = {}

              args.keys.each do |arg|
                val = args[arg]
                params[:filter] ||= {}

                filter, operator = filter_map[arg]

                params[:filter][filter] ||= {}
                params[:filter][filter][operator] = val
              end

              loader.for(sideload, attribute, params: params, single: is_single).load(is_entrypoint ? :entry : obj)
            }
          end

        end
      end
    end
  end
end