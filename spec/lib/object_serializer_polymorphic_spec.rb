require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  class List
    attr_accessor :id, :name, :items
  end

  class ChecklistItem
    attr_accessor :id, :name
  end

  class Car
    attr_accessor :id, :model, :year
  end

  class Animal
    attr_accessor :id, :uuid, :species
  end

  class ListSerializer
    include FastJsonapi::ObjectSerializer
    set_type :list
    attributes :name
    set_key_transform :dash
    has_many :items, polymorphic: true
  end

  class ZooSerializer
    include FastJsonapi::ObjectSerializer
    set_type :list
    attributes :name
    has_many :items, polymorphic: true, id_method_name: :uuid
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

  let(:animal) do
    animal = Animal.new
    animal.id = 1
    animal.species = 'Mellivora capensis'
    animal.uuid = 'sdfsdfds'
    animal
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

    it 'should use the correct id method on associated objects' do
      list = List.new
      list.id = 1
      list.items = [animal]
      list_hash = ZooSerializer.new(list).to_hash
      id = list_hash[:data][:relationships][:items][:data][0][:id]
      expect(id).to eq animal.uuid
    end
  end
end
