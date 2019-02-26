RSpec.shared_context "ams group class" do
  before(:context) do
    # models
    class AMSPerson < ActiveModelSerializers::Model
      attr_accessor :id, :first_name, :last_name
    end

    class AMSGroup < ActiveModelSerializers::Model
      attr_accessor :id, :name, :groupees
    end

    # serializers
    class AMSPersonSerializer < ActiveModel::Serializer
      type "person"
      attributes :first_name, :last_name
    end

    class AMSGroupSerializer < ActiveModel::Serializer
      type "group"
      attributes :name
      has_many :groupees
    end
  end

  after(:context) do
    %i[AMSPerson AMSGroup AMSPersonSerializer AMSGroupSerializer].each do |klass_name|
      Object.__send__(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end

  let(:ams_groups) do
    build_ams_groups(3)
  end

  let(:ams_person) do
    AMSPerson.new.tap { |ams_person| ams_person.id = 3 }
  end

  def build_ams_groups(count)
    group_count = 0
    person_count = 0

    Array.new(count) do
      AMSGroup.new.tap do |group|
        group.id = group_count + 1
        group.name = "Test Group #{group.id}"
        group_count = group.id

        group.groupees = [
          AMSPerson.new.tap do |person|
            person.id = person_count + 1
            person.last_name = "Last Name #{person.id}"
            person.first_name = "First Name #{person.id}"
            person_count = person.id
          end,

          AMSGroup.new.tap do |child_group|
            child_group.id = group_count + 1
            child_group.name = "Test Group #{child_group.id}"
            group_count = child_group.id
          end
        ]
      end
    end
  end
end
