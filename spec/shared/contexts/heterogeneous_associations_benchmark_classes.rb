RSpec.shared_context 'heterogeneous associations benchmark classes' do
  # Tasks & Projects classes:
  before(:context) do
    # All models should implement the minimum set of methods for all serializers to work:
    class BaseBenchmarkModel
      alias :read_attribute_for_serialization :send
      def self.model_name
        @_model_name ||= ActiveModel::Name.new(self)
      end
    end

    class Task < BaseBenchmarkModel
      attr_accessor :id, :title
    end

    class BigTask < Task
      attr_accessor :description
    end

    class BaseProject < BaseBenchmarkModel
      attr_accessor :id, :name
    end

    class SingleTaskProject < BaseProject
      attr_accessor :task
    end

    class ReferencedTaskProject < SingleTaskProject
      attr_accessor :task_id
    end

    class MultiTaskProject < BaseProject
      attr_accessor :tasks
    end

    class MultiReferencedTaskProject < MultiTaskProject
      attr_accessor :task_ids
    end

    # FastJsonapi Serializers
    class HomogeneousHasOneSerializer
      include FastJsonapi::ObjectSerializer
      set_type :test_project
      attributes :name
      has_one :task, record_type: :big_task
    end

    class HomogeneousHasManySerializer
      include FastJsonapi::ObjectSerializer
      set_type :test_project
      attributes :name
      has_many :tasks, record_type: :big_task
    end

    class HeterogeneousHasOneSerializer
      include FastJsonapi::ObjectSerializer
      set_type :test_project
      attributes :name
      has_one :task
    end

    class HeterogeneousHasManySerializer
      include FastJsonapi::ObjectSerializer
      set_type :test_project
      attributes :name
      has_many :tasks
    end

    # active_model_serializers Serializers:
    class TaskSerializer < ActiveModel::Serializer
      type 'task'
      attributes :title
    end

    class BigTaskSerializer < TaskSerializer
      type 'big_task'
      attributes :description
    end

    class AMSHasOneSerializer < ActiveModel::Serializer
      type 'test_project'
      attributes :name
      has_one :task
    end

    class AMSHasManySerializer < ActiveModel::Serializer
      type 'test_project'
      attributes :name
      has_many :tasks
    end

    # jsonapi-rb Serializers:
    class JSONAPIHasOneSerializer < JSONAPI::Serializable::Resource
      type 'test_project'
      attributes :name
      has_one :task
    end

    class JSONAPIHasManySerializer < JSONAPI::Serializable::Resource
      type 'test_project'
      attributes :name
      has_many :tasks
    end

    class JSONAPIHeterogeneousAssociationsSerializer
      def initialize(data, options = {})
        @serializer = JSONAPI::Serializable::Renderer.new
        @options = options.merge(class: {
          MultiTaskProject: JSONAPIHasManySerializer,
          SingleTaskProject: JSONAPIHasOneSerializer,
          ReferencedTaskProject: JSONAPIHasOneSerializer,
          MultiReferencedTaskProject: JSONAPIHasManySerializer
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

  after(:context) do
    # %i[
    #   Task
    #   BigTask
    #   MultiTaskProject
    #   SingleTaskProject
    #   BaseBenchmarkModel
    #   ReferencedTaskProject
    #   MultiReferencedTaskProject
    #   AMSHasOneSerializer
    #   AMSHasManySerializer
    #   JSONAPIHasOneSerializer
    #   JSONAPIHasManySerializer
    #   HomogeneousHasOneSerializer
    #   HomogeneousHasManySerializer
    #   HeterogeneousHasOneSerializer
    #   HeterogeneousHasManySerializer
    # ].each do |klass_name|
    #   Object.send(:remove_const, klass_name) if Object.constants.include?(klass_name)
    # end
  end

  # FastJsonapiHeterogeneous has_one case:
  def build_heterogeneous_has_one_objects(count)
    task_counts = { Task => 0, BigTask => 0 }
    count.times.map do |id|
      task_class = (id % 2 == 0) ? BigTask : Task
      SingleTaskProject.new.tap do |project|
        project.id = id + 1
        project.name = "Test Project #{id}"
        project.task = task_class.new.tap do |task|
          task.id = (task_counts[task_class] += 1)
          task.title = "Test Task #{task.id}"
          task.description = "Test Task Description #{task.id}" if task_class == BigTask
        end
      end
    end
  end

  # FastJsonapiHomogeneous has_one case:
  def build_homogeneous_has_one_objects(count)
    task_count = 0
    count.times.map do |id|
      SingleTaskProject.new.tap do |project|
        project.id = id + 1
        project.name = "Test Project #{id}"
        project.task = BigTask.new.tap do |task|
          task.id = task_count += 1
          task.title = "Test Task #{task.id}"
          task.description = "Test Task Description #{task.id}"
        end
      end
    end
  end

  # FastJsonapiHomogeneous has_one with association_id case:
  def build_homogeneous_has_one_with_id_objects(count)
    task_count = 0
    count.times.map do |id|
      ReferencedTaskProject.new.tap do |project|
        project.id = id + 1
        project.name = "Test Project #{id}"
        project.task = BigTask.new.tap do |task|
          task.id = task_count += 1
          task.title = "Test Task #{task.id}"
          task.description = "Test Task Description #{task.id}"
        end
        project.task_id = project.task.id
      end
    end
  end

  # FastJsonapiHeterogeneous has_many case:
  def build_heterogeneous_has_many_objects(count)
    task_count = 0
    task_counts_per_class = { Task => 0, BigTask => 0 }
    count.times.map do |id|
      MultiTaskProject.new.tap do |project|
        project.id = id + 1
        project.name = "Test Project #{id}"
        project.tasks = 5.times.map do |task_number|
          task_count += 1
          task_class = (task_count % 2 == 0) ? BigTask : Task
          task_class.new.tap do |task|
            task.id = (task_counts_per_class[task_class] += 1)
            task.title = "Test Task #{task.id}"
            task.description = "Test Task Description #{task.id}" if task_class == BigTask
          end
        end
      end
    end
  end

  # FastJsonapiHomogeneous has_many case:
  def build_homogeneous_has_many_objects(count)
    task_count = 0
    count.times.map do |id|
      MultiTaskProject.new.tap do |project|
        project.id = id + 1
        project.name = "Test Project #{id}"
        project.tasks = 5.times.map do |task_number|
          BigTask.new.tap do |task|
            task.id = task_count += 1
            task.title = "Test Task #{task.id}"
            task.description = "Test Task Description #{task.id}"
          end
        end
      end
    end
  end

  # FastJsonapiHomogeneous has_many with association_ids case:
  def build_homogeneous_has_many_with_ids_objects(count)
    task_count = 0
    count.times.map do |id|
      MultiReferencedTaskProject.new.tap do |project|
        project.id = id + 1
        project.name = "Test Project #{id}"
        project.tasks = 5.times.map do |task_number|
          BigTask.new.tap do |task|
            task.id = task_count += 1
            task.title = "Test Task #{task.id}"
            task.description = "Test Task Description #{task.id}"
          end
        end
        project.task_ids = project.tasks.map(&:id)
      end
    end
  end
end
