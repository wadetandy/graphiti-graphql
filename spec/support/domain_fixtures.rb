require 'active_model'

class ApplicationRecord
  include ActiveModel::Model
end

class Classification < ApplicationRecord
end

class Team < ApplicationRecord
end

class EmployeeTeam < ApplicationRecord
end

class Office < ApplicationRecord
end

class HomeOffice < ApplicationRecord
end

class Employee < ApplicationRecord
end

class Position < ApplicationRecord
end

class Department < ApplicationRecord
end

class Salary < ApplicationRecord
end

class ApplicationResource < Graphiti::Resource
  self.adapter = Graphiti::Adapters::Null
  self.abstract_class = true
  self.autolink = false
end

class ClassificationResource < ApplicationResource
end

class TeamResource < ApplicationResource
  attribute :name, :string
end

class DepartmentResource < ApplicationResource
  attribute :name, :string
end

class DepartmentSearchResource < ApplicationResource
  attribute :name, :string
end

class PositionResource < ApplicationResource
  attribute :employee_id, :integer, only: [:writable]
  attribute :title, :string
  belongs_to :department
end

class OfficeResource < ApplicationResource
  attribute :address, :string
end

class HomeOfficeResource < ApplicationResource
  # self.description = "An employee's primary office location"

  attribute :address, :string
end

class SalaryResource < ApplicationResource
  # self.description = "An employee salary"

  attribute :employee_id, :integer, only: [:writable]
  attribute :base_rate, :float
  attribute :overtime_rate, :float
end

class EmployeeResource < ApplicationResource
  attribute :first_name, :string, description: "The employee's first name"
  attribute :last_name, :string, description: "The employee's last name"
  attribute :age, :integer

  extra_attribute :nickname, :string
  extra_attribute :salutation, :string
  extra_attribute :professional_titles, :string

  has_many :positions
  has_one :salary
  belongs_to :classification
  many_to_many :teams, foreign_key: { teams: :employee_id }
  polymorphic_belongs_to :workspace do
    group_by(:workspace_type) do
      on(:Office)
      on(:HomeOffice)
    end
  end
end

class EmployeeSearchResource < ApplicationResource
  attribute :first_name, :string
  attribute :last_name, :string
  attribute :age, :integer
end