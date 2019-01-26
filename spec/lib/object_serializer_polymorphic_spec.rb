require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  class ListOwner
    attr_accessor :id, :uuid
  end

  class List
    attr_accessor :id, :name, :items, :owner, :owner_id, :owner_type, :owner_uuid
  end

  class ChecklistItem
    attr_accessor :id, :name
  end

  class Car
    attr_accessor :id, :model, :year
  end

  class ListSerializer
    include FastJsonapi::ObjectSerializer
    set_type :list
    attributes :name
    set_key_transform :dash
    has_many :items, polymorphic: true
    belongs_to :owner, polymorphic: true, id_method_name: :owner_uuid
    belongs_to :owner_block, polymorphic: true, id_method_name: :uuid do
      owner = ListOwner.new
      owner.id = 2
      owner.uuid = 234234234
      owner
    end
  end

  let(:car) do
    car = Car.new
    car.id = 1
    car.model = 'Toyota Corolla'
    car.year = 1987
    car
  end

  let(:checklist_item) do
    checklist_item = ChecklistItem.new
    checklist_item.id = 2
    checklist_item.name = 'Do this action!'
    checklist_item
  end

  let(:owner) do
    owner = ListOwner.new
    owner.id = 1
    owner.uuid = 123123123
    owner
  end

  context 'when serializing id and type of polymorphic relationships' do
    it 'should return correct type when transform_method is specified' do
      list = List.new
      list.id = 1
      list.items = [checklist_item, car]
      list_hash = ListSerializer.new(list).to_hash
      record_type = list_hash[:data][:relationships][:items][:data][0][:type]
      expect(record_type).to eq 'checklist-item'.to_sym
      record_type = list_hash[:data][:relationships][:items][:data][1][:type]
      expect(record_type).to eq 'car'.to_sym
    end

    it 'should return correct id for belongs_to when id_method_name is specified' do
      list = List.new
      list.id = 1
      list.owner = owner
      list.owner_id = owner.id
      list.owner_type = owner.class.name
      list.owner_uuid = owner.uuid
      list_hash = ListSerializer.new(list).to_hash
      record_uuid = list_hash[:data][:relationships][:owner][:data][:id]
      expect(record_uuid).to eq list.owner_uuid
    end

    it 'should return nil for belongs_to when association is nil' do
      list = List.new
      list.id = 1
      list_hash = ListSerializer.new(list).to_hash
      owner_relationship = list_hash[:data][:relationships][:owner][:data]
      expect(owner_relationship).to be_nil
    end

    it 'should return nil for belongs_to when association is nil' do
      list = List.new
      list.id = 1
      list_hash = ListSerializer.new(list).to_hash
      owner_relationship = list_hash[:data][:relationships][:'owner-block'][:data]
      expect(owner_relationship).to eq(id: 234234234, type: :'list-owner')
    end
  end
end
