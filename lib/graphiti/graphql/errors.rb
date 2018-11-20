module Graphiti
  module Graphql
    class Error < StandardError; end;
    class ResourceInferenceError < Error
      def initialize(name, expected)
        @name = name
        @expected = expected
      end

      def message
        "Could not infer resource for name \"#{@name}\". Expected #{@expected} to be defined."
      end
    end

    class ExpectedResourceClassError < Error
      def initialize(klass)
        @klass = klass
      end

      def message
        "Expected a subclass of Graphiti::Resource. Got #{@klass}"
      end
    end
  end
end