# frozen_string_literal: true

RSpec.shared_context 'group class' do
  # Person, Group Classes and serializers
  before(:context) do
    # models
    class Person
      attr_accessor :id, :first_name, :last_name
    end

    class Group
      attr_accessor :id, :name, :groupees # Let's assume groupees can be Person or Group objects
    end

    # serializers
    class PersonSerializer
      include FastJsonapi::ObjectSerializer
      set_type :person
      attributes :first_name, :last_name
    end

    class GroupSerializer
      include FastJsonapi::ObjectSerializer
      set_type :group
      attributes :name
      has_many :groupees, polymorphic: true
    end
  end

  # Person and Group struct
  before(:context) do
    PersonStruct = Struct.new(
      :id, :first_name, :last_name
    )

    GroupStruct = Struct.new(
      :id, :name, :groupees, :groupee_ids
    )
  end

  after(:context) do
    classes_to_remove = %i[
      Person
      PersonSerializer
      Group
      GroupSerializer
      PersonStruct
      GroupStruct
    ]
    classes_to_remove.each do |klass_name|
      Object.send(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end

  let(:group) do
    group = Group.new
    group.id = 1
    group.name = 'Group 1'

    person = Person.new
    person.id = 1
    person.last_name = 'Last Name 1'
    person.first_name = 'First Name 1'

    child_group = Group.new
    child_group.id = 2
    child_group.name = 'Group 2'

    group.groupees = [person, child_group]
    group
  end

  def build_groups(count)
    group_count = 0
    person_count = 0

    count.times.map do |_i|
      group = Group.new
      group.id = group_count + 1
      group.name = "Test Group #{group.id}"
      group_count = group.id

      person = Person.new
      person.id = person_count + 1
      person.last_name = "Last Name #{person.id}"
      person.first_name = "First Name #{person.id}"
      person_count = person.id

      child_group = Group.new
      child_group.id = group_count + 1
      child_group.name = "Test Group #{child_group.id}"
      group_count = child_group.id

      group.groupees = [person, child_group]
      group
    end
  end
end
