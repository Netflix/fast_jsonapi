# frozen_string_literal: true

require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  after(:all) do
    classes_to_remove = %i[
      User
      UserSerializer
      Country
      CountrySerializer
      Employee
      EmployeeSerializer
      Photo
      PhotoSerializer
      EmployeeAccount
    ]
    classes_to_remove.each do |klass_name|
      Object.send(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end

  class User
    attr_accessor :id, :first_name, :last_name

    attr_accessor :address_ids, :country_id

    def photo
      p = Photo.new
      p.id = 1
      p.user_id = id
      p
    end

    def photo_id
      1
    end
  end

  class UserSerializer
    include FastJsonapi::ObjectSerializer
    set_type :user
    attributes :first_name, :last_name

    attribute :full_name do |user, _params|
      "#{user.first_name} #{user.last_name}"
    end

    has_many :addresses, cached: true
    belongs_to :country
    has_one :photo
  end

  class Photo
    attr_accessor :id, :user_id
  end

  class PhotoSerializer
    include FastJsonapi::ObjectSerializer
    attributes :id, :name
  end

  class Country
    attr_accessor :id, :name
  end

  class CountrySerializer
    include FastJsonapi::ObjectSerializer
    attributes :name
  end

  class EmployeeAccount
    attr_accessor :id, :employee_id
  end

  class Employee < User
    attr_accessor :id, :location, :compensation

    def account
      a = EmployeeAccount.new
      a.id = 1
      a.employee_id = id
      a
    end

    def account_id
      1
    end
  end

  class EmployeeSerializer < UserSerializer
    include FastJsonapi::ObjectSerializer
    attributes :location
    attributes :compensation

    has_one :account
  end

  it 'sets the correct record type' do
    expect(EmployeeSerializer.reflected_record_type).to eq :employee
    expect(EmployeeSerializer.record_type).to eq :employee
  end

  context 'when testing inheritance of attributes' do
    it 'includes parent attributes' do
      subclass_attributes = EmployeeSerializer.attributes_to_serialize
      superclass_attributes = UserSerializer.attributes_to_serialize
      expect(subclass_attributes).to include(superclass_attributes)
    end

    it 'returns inherited attribute with a block correctly' do
      e = Employee.new
      e.id = 1
      e.first_name = 'S'
      e.last_name = 'K'
      attributes_hash = EmployeeSerializer.new(e).serializable_hash[:data][:attributes]
      expect(attributes_hash).to include(full_name: 'S K')
    end

    it 'includes child attributes' do
      expect(EmployeeSerializer.attributes_to_serialize[:location].method).to eq(:location)
    end

    it 'doesnt change parent class attributes' do
      EmployeeSerializer
      expect(UserSerializer.attributes_to_serialize).not_to have_key(:location)
    end
  end

  context 'when testing inheritance of relationship' do
    it 'includes parent relationships' do
      subclass_relationships = EmployeeSerializer.relationships_to_serialize
      superclass_relationships = UserSerializer.relationships_to_serialize
      expect(subclass_relationships).to include(superclass_relationships)
    end

    it 'returns inherited relationship correctly' do
      e = Employee.new
      e.country_id = 1
      relationships_hash = EmployeeSerializer.new(e).serializable_hash[:data][:relationships][:country]
      expect(relationships_hash).to include(data: { id: '1', type: :country })
    end

    it 'includes child relationships' do
      expect(EmployeeSerializer.relationships_to_serialize.keys).to include(:account)
    end

    it 'doesnt change parent class attributes' do
      EmployeeSerializer
      expect(UserSerializer.relationships_to_serialize.keys).not_to include(:account)
    end

    it 'includes parent cached relationships' do
      subclass_relationships = EmployeeSerializer.cachable_relationships_to_serialize
      superclass_relationships = UserSerializer.cachable_relationships_to_serialize
      expect(subclass_relationships).to include(superclass_relationships)
    end
  end

  context 'when test inheritence of other attributes' do
    it 'inherits the tranform method' do
      EmployeeSerializer
      expect(UserSerializer.transform_method).to eq EmployeeSerializer.transform_method
    end
  end
end
