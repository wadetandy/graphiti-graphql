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

      SIDELOAD_TYPES = {
        belongs_to: Graphiti::Sideload::BelongsTo,
        has_one: Graphiti::Sideload::HasOne,
        has_many: Graphiti::Sideload::HasMany,
        many_to_many: Graphiti::Sideload::ManyToMany
      }

      def initialize(base_class)
        @type_map = {}
        @sideload_for_type = {}
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
        get_type = method(:type_for_resource)

        @type_map[type_name] ||= GraphQL::ObjectType.define do
          name type_name.singularize.camelize

          description "A #{type_name.singularize}"

          resource_class.all_attributes.each_pair do |att, details|
            if details[:readable]
              field att, GRAPHQL_SCALAR_TYPE_MAP[details[:type]]
            end
          end

          resource_class.sideloads.each_pair do |sideload_name, sideload|
            next if sideload_name.in?([:notes, :notable])
            next if sideload.polymorphic_child?# || sideload_polymorphic_parent?

            is_single = sideload.single? || sideload.type.in?([:belongs_to, :has_one])

            type_proc = -> {
              sideload_type = get_type.call(sideload.resource_class)
              is_single ? sideload_type : types[sideload_type]
            }

            field sideload_name, type_proc do
              resolve -> (obj, args, ctx) {
                if sideload.type == :belongs_to
                  attribute = sideload.primary_key
                  value = obj.send(sideload.foreign_key)
                else
                  attribute = sideload.foreign_key
                  value = obj.send(sideload.primary_key)
                end

                if is_single
                  BatchLoader::SingleItemLoader.for(sideload.resource_class, attribute).load(value)
                else
                  BatchLoader::MultiItemLoader.for(sideload.resource_class, attribute).load(value)
                end
              }
            end

          end
        end

        @sideload_for_type[type_name] ||= {}
        @sideload_for_type[type_name].merge!(resource_class.sideloads)

        resource_class.sideloads.values.each do |sideload|
          next if sideload.resource_class.type.blank?
          add_resource(sideload.resource_class)
        end
      end

      def finalize
      end

      private

      def type_for_resource(resource_class)
        type_name = resource_class.type.to_s
        @type_map[type_name]
      end
    end
  end
end