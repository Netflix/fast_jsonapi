# frozen_string_literal: true

RSpec.shared_context 'ams group class' do
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
      type 'person'
      attributes :first_name, :last_name
    end

    class AMSGroupSerializer < ActiveModel::Serializer
      type 'group'
      attributes :name
      has_many :groupees
    end
  end

  after(:context) do
    classes_to_remove = %i[AMSPerson AMSGroup AMSPersonSerializer AMSGroupSerializer]
    classes_to_remove.each do |klass_name|
      Object.send(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end

  let(:ams_groups) do
    group_count = 0
    person_count = 0
    3.times.map do |_i|
      group = AMSGroup.new
      group.id = group_count + 1
      group.name = "Test Group #{group.id}"
      group_count = group.id

      person = AMSPerson.new
      person.id = person_count + 1
      person.last_name = "Last Name #{person.id}"
      person.first_name = "First Name #{person.id}"
      person_count = person.id

      child_group = AMSGroup.new
      child_group.id = group_count + 1
      child_group.name = "Test Group #{child_group.id}"
      group_count = child_group.id

      group.groupees = [person, child_group]
      group
    end
  end

  let(:ams_person) do
    ams_person = AMSPerson.new
    ams_person.id = 3
    ams_person
  end

  def build_ams_groups(count)
    group_count = 0
    person_count = 0
    count.times.map do |_i|
      group = AMSGroup.new
      group.id = group_count + 1
      group.name = "Test Group #{group.id}"
      group_count = group.id

      person = AMSPerson.new
      person.id = person_count + 1
      person.last_name = "Last Name #{person.id}"
      person.first_name = "First Name #{person.id}"
      person_count = person.id

      child_group = AMSGroup.new
      child_group.id = group_count + 1
      child_group.name = "Test Group #{child_group.id}"
      group_count = child_group.id

      group.groupees = [person, child_group]
      group
    end
  end
end
