# frozen_string_literal: true

RSpec.shared_context 'jsonapi-serializers group class' do
  # Person, Group Classes and serializers
  before(:context) do
    # models
    class JSPerson
      attr_accessor :id, :first_name, :last_name
    end

    class JSGroup
      attr_accessor :id, :name, :groupees # Let's assume groupees can be Person or Group objects
    end

    # serializers
    class JSPersonSerializer
      include JSONAPI::Serializer
      attributes :first_name, :last_name

      def type
        'person'
      end
    end

    class JSGroupSerializer
      include JSONAPI::Serializer
      attributes :name
      has_many :groupees

      def type
        'group'
      end
    end

    class JSONAPISSerializerB
      def initialize(data, options = {})
        @options = options.merge(is_collection: true)
        @data = data
      end

      def to_json(*_args)
        JSON.fast_generate(to_hash)
      end

      def to_hash
        JSONAPI::Serializer.serialize(@data, @options)
      end
    end
  end

  after :context do
    classes_to_remove = %i[
      JSPerson
      JSGroup
      JSPersonSerializer
      JSGroupSerializer
    ]
    classes_to_remove.each do |klass_name|
      Object.send(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end

  let(:jsonapi_groups) do
    group_count = 0
    person_count = 0
    3.times.map do |_i|
      group = JSGroup.new
      group.id = group_count + 1
      group.name = "Test Group #{group.id}"
      group_count = group.id

      person = JSPerson.new
      person.id = person_count + 1
      person.last_name = "Last Name #{person.id}"
      person.first_name = "First Name #{person.id}"
      person_count = person.id

      child_group = JSGroup.new
      child_group.id = group_count + 1
      child_group.name = "Test Group #{child_group.id}"
      group_count = child_group.id

      group.groupees = [person, child_group]
      group
    end
  end

  let(:jsonapis_person) do
    person = JSPerson.new
    person.id = 3
    person
  end

  def build_jsonapis_groups(count)
    group_count = 0
    person_count = 0
    count.times.map do |_i|
      group = JSGroup.new
      group.id = group_count + 1
      group.name = "Test Group #{group.id}"
      group_count = group.id

      person = JSPerson.new
      person.id = person_count + 1
      person.last_name = "Last Name #{person.id}"
      person.first_name = "First Name #{person.id}"
      person_count = person.id

      child_group = JSGroup.new
      child_group.id = group_count + 1
      child_group.name = "Test Group #{child_group.id}"
      group_count = child_group.id

      group.groupees = [person, child_group]
      group
    end
  end
end
