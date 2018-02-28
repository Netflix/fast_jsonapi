RSpec.shared_context 'jsonapi group class' do

  # Person, Group Classes and serializers
  before(:context) do
    # models
    class JSONAPIPerson
      attr_accessor :id, :first_name, :last_name
    end

    class JSONAPIGroup
      attr_accessor :id, :name, :groupees # Let's assume groupees can be Person or Group objects
    end

    # serializers
    class JSONAPIPersonSerializer < JSONAPI::Serializable::Resource
      type 'person'
      attributes :first_name, :last_name
    end

    class JSONAPIGroupSerializer < JSONAPI::Serializable::Resource
      type 'group'
      attributes :name
      has_many :groupees
    end

    class JSONAPISerializerB
      def initialize(data, options = {})
        @serializer = JSONAPI::Serializable::Renderer.new
        @options = options.merge(class: {
          JSONAPIPerson: JSONAPIPersonSerializer,
          JSONAPIGroup: JSONAPIGroupSerializer
        })
        @data = data
      end

      def to_json
        @serializer.render(@data, @options).to_json
      end

      def to_hash
        @serializer.render(@data, @options)
      end
    end
  end

  after :context do
    classes_to_remove = %i[
      JSONAPIPerson
      JSONAPIGroup
      JSONAPIPersonSerializer
      JSONAPIGroupSerializer]
    classes_to_remove.each do |klass_name|
      Object.send(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end

  let(:jsonapi_groups) do
    group_count = 0
    person_count = 0
    3.times.map do |i|
      group = JSONAPIGroup.new
      group.id = group_count + 1
      group.name = "Test Group #{group.id}"
      group_count = group.id

      person = JSONAPIPerson.new
      person.id = person_count + 1
      person.last_name = "Last Name #{person.id}"
      person.first_name = "First Name #{person.id}"
      person_count = person.id

      child_group = JSONAPIGroup.new
      child_group.id = group_count + 1
      child_group.name = "Test Group #{child_group.id}"
      group_count = child_group.id

      group.groupees = [person, child_group]
      group
    end
  end

  let(:jsonapi_person) do
    person = JSONAPIPerson.new
    person.id = 3
    person
  end

  def build_jsonapi_groups(count)
    group_count = 0
    person_count = 0
    count.times.map do |i|
      group = JSONAPIGroup.new
      group.id = group_count + 1
      group.name = "Test Group #{group.id}"
      group_count = group.id

      person = JSONAPIPerson.new
      person.id = person_count + 1
      person.last_name = "Last Name #{person.id}"
      person.first_name = "First Name #{person.id}"
      person_count = person.id

      child_group = JSONAPIGroup.new
      child_group.id = group_count + 1
      child_group.name = "Test Group #{child_group.id}"
      group_count = child_group.id

      group.groupees = [person, child_group]
      group
    end
  end
end
