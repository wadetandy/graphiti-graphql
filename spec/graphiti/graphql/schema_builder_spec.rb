require 'spec_helper'

RSpec.describe Graphiti::Graphql::SchemaBuilder do
  let(:instance) { described_class.new }

  describe '#build' do
    subject(:schema) { instance.build(&builder_block) }

    describe "#resource" do
      describe "when simple resource is defined" do
        let(:builder_block) do
          Proc.new do
            resource :departments
          end
        end

        it "creates queries for both single and multiple resources" do
          expect(schema.query_entrypoints).to eq({
            department: { resource: DepartmentResource, singular: true },
            departments: { resource: DepartmentResource, singular: false },
          })
        end
      end

      describe 'when an explicit resource is provided' do
        let(:builder_block) do
          Proc.new do
            resource :departments, resource_class: EmployeeResource
          end
        end

        it "uses the provided resource" do
          expect(schema.query_entrypoints).to eq({
            department: { resource: EmployeeResource, singular: true },
            departments: { resource: EmployeeResource, singular: false },
          })
        end
      end

      describe "only show" do
        let(:builder_block) do
          Proc.new do
            resource :departments, only: :show
          end
        end

        it "creates queries for only show action" do
          expect(schema.query_entrypoints).to eq({
            department: { resource: DepartmentResource, singular: true },
          })
        end
      end

      describe "only index" do
        let(:builder_block) do
          Proc.new do
            resource :departments, only: :index
          end
        end

        it "creates queries only index action" do
          expect(schema.query_entrypoints).to eq({
            departments: { resource: DepartmentResource, singular: false },
          })
        end
      end

      describe "when an explicit index resource is provided" do
        let(:builder_block) do
          Proc.new do
            resource :departments, index: DepartmentSearchResource
          end
        end

        it "uses the override for the index action" do
          expect(schema.query_entrypoints).to eq({
            department: { resource: DepartmentResource, singular: true },
            departments: { resource: DepartmentSearchResource, singular: false },
          })
        end
      end

      describe "when an explicit show resource is provided" do
        let(:builder_block) do
          Proc.new do
            resource :departments, show: DepartmentSearchResource
          end
        end

        it "uses the override for the show action" do
          expect(schema.query_entrypoints).to eq({
            departments: { resource: DepartmentResource, singular: false },
            department: { resource: DepartmentSearchResource, singular: true },
          })
        end
      end

      describe 'when the resource name cannot be inferred' do
        let(:builder_block) do
          Proc.new do
            resource :unknowns
          end
        end

        it "raises an error" do
          expect { schema }.to raise_error(Graphiti::Graphql::ResourceInferenceError, /Expected UnknownResource to be defined/)
        end
      end

      describe 'when non-resource class is provided' do
        let(:builder_block) do
          Proc.new do
            resource :departments, resource_class: String
          end
        end

        it "raises an error" do
          expect { schema }.to raise_error(Graphiti::Graphql::ExpectedResourceClassError, /Expected a subclass of Graphiti::Resource/)
        end
      end
    end

    describe '#raw' do
      let(:builder_block) do
        block = raw_block

        Proc.new do
          raw(&block)
        end
      end

      let(:raw_block) do
        Proc.new do
          mutate(Foo)
        end
      end

      it 'Adds the raw block to the schema definition' do
        expect(schema.raw_blocks).to eq [raw_block]
      end
    end
  end
end