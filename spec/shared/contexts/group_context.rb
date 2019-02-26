RSpec.shared_context "group class" do
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
    %i[
      Person
      PersonSerializer
      Group
      GroupSerializer
      PersonStruct
      GroupStruct
    ].each do |klass_name|
      Object.__send__(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end

  let(:group) do
    build_groups(1).first.tap do |group|
      [group.name, group.groupees.last.name].each { |s| s.sub("Test ", "") }
    end
  end

  def build_groups(count)
    group_count = 0
    person_count = 0

    Array.new(count) do
      Group.new.tap do |group|
        group.id = group_count + 1
        group.name = "Test Group #{group.id}"
        group_count = group.id

        group.groupees = [
          Person.new.tap do |person|
            person.id = person_count + 1
            person.last_name = "Last Name #{person.id}"
            person.first_name = "First Name #{person.id}"
            person_count = person.id
          end,

          Group.new.tap do |child_group|
            child_group.id = group_count + 1
            child_group.name = "Test Group #{child_group.id}"
            group_count = child_group.id
          end
        ]
      end
    end
  end
end
