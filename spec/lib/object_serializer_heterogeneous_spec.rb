require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  class Vehicle
    attr_accessor :id, :model, :year

    def type
      self.class.name.downcase
    end
  end

  class Car < Vehicle
    attr_accessor :purchased_at
  end

  class Bus < Vehicle
    attr_accessor :passenger_count
  end

  class Truck < Vehicle
    attr_accessor :load
  end

  class VehicleSerializer
    include FastJsonapi::ObjectSerializer
    attributes :model, :year
  end

  class CarSerializer < VehicleSerializer
    attribute :purchased_at
  end

  class BusSerializer < VehicleSerializer
    attribute :passenger_count
  end

  let(:car) do
    car = Car.new
    car.id = 1
    car.model = 'Toyota Corolla'
    car.year = 1987
    car.purchased_at = Time.new(2018, 1, 1)
    car
  end

  let(:bus) do
    bus = Bus.new
    bus.id = 2
    bus.model = 'Nova Bus LFS'
    bus.year = 2014
    bus.passenger_count = 60
    bus
  end

  let(:truck) do
    truck = Truck.new
    truck.id = 3
    truck.model = 'Ford F150'
    truck.year = 2000
    truck
  end

  context 'when serializing a heterogenous collection' do
    it 'should use the correct serializer for each item' do
      vehicles = VehicleSerializer.new([car, bus], serializers: { Car: CarSerializer, Bus: BusSerializer }).to_hash
      car, bus = vehicles[:data]

      expect(car[:type]).to eq(:car)
      expect(car[:attributes]).to eq(model: 'Toyota Corolla', year: 1987, purchased_at: Time.new(2018, 1, 1))

      expect(bus[:type]).to eq(:bus)
      expect(bus[:attributes]).to eq(model: 'Nova Bus LFS', year: 2014, passenger_count: 60)
    end

    context 'if there is no serializer given for the class' do
      it 'should raise ArgumentError' do
        expect { VehicleSerializer.new([truck], serializers: { Car: CarSerializer, Bus: BusSerializer }).to_hash }
          .to raise_error(ArgumentError, 'no serializer defined for Truck')
      end
    end

    context 'when given an empty set of serializers' do
      it 'should use the serializer being called' do
        data = VehicleSerializer.new([truck], serializers: {}).to_hash[:data][0]
        expect(data[:type]).to eq(:vehicle)
        expect(data[:attributes]).to eq(model: 'Ford F150', year: 2000)
      end
    end
  end

  context 'when serializing an arbitrary object' do
    it 'should use the correct serializer' do
      data = VehicleSerializer.new(car, serializers: { Car: CarSerializer, Bus: BusSerializer }).to_hash[:data]

      expect(data[:type]).to eq(:car)
      expect(data[:attributes]).to eq(model: 'Toyota Corolla', year: 1987, purchased_at: Time.new(2018, 1, 1))
    end

    context 'if there is no serializer given for the class' do
      it 'should raise ArgumentError' do
        expect { VehicleSerializer.new(truck, serializers: { Car: CarSerializer, Bus: BusSerializer }).to_hash }
          .to raise_error(ArgumentError, 'no serializer defined for Truck')
      end
    end

    context 'when given an empty set of serializers' do
      it 'should use the serializer being called' do
        data = VehicleSerializer.new(truck, serializers: {}).to_hash[:data]
        expect(data[:type]).to eq(:vehicle)
        expect(data[:attributes]).to eq(model: 'Ford F150', year: 2000)
      end
    end
  end
end
