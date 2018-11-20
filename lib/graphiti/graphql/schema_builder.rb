module Graphiti
  module Graphql
    class SchemaBuilder
      def self.build(&block)
        new.build(&block).generate_schema
      end

      def build(&block)
        @schema = Graphiti::Graphql::Schema.new
        instance_eval(&block)
        @schema.tap do
          @schema = nil
        end
      end

      def resource(name, only: nil, show: nil, index: nil, resource_class: nil)
        name = name.to_s
        resource_class ||= infer_resource(name)

        ensure_resource_class(resource_class)

        index_resource = index || resource_class unless only == :show
        show_resource = show || resource_class unless only == :index

        ensure_resource_class(index_resource)
        ensure_resource_class(show_resource)

        @schema.add_entrypoint(name.singularize, show_resource, true) if show_resource
        @schema.add_entrypoint(name.pluralize, index_resource, false) if index_resource
      end

      def raw(&block)
        @schema.add_raw_block(block)
      end

      private

      def infer_resource(name)
        inferred_name = "#{name.singularize.classify}Resource"
        inferred_name.safe_constantize.tap do |resource_class|
          unless resource_class
            raise ResourceInferenceError.new(name, inferred_name)
          end
        end
      end

      def ensure_resource_class(klass)
        return unless klass

        unless klass.respond_to?(:ancestors) && klass.ancestors.include?(Graphiti::Resource)
          raise ExpectedResourceClassError.new(klass)
        end
      end
    end
  end
end