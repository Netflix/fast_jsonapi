require 'spec_helper'

describe FastJsonapi::ObjectSerializer, performance: true do
  include_context 'movie class'
  include_context 'ams movie class'

  before(:all) { GC.disable }
  after(:all) { GC.enable }

  context 'when testing performance of serialization' do
    it 'should create a hash of 1000 records in less than 50 ms' do
      movies = 1000.times.map { |_i| movie }
      expect { MovieSerializer.new(movies).serializable_hash }.to perform_under(50).ms
    end

    it 'should serialize 1000 records to jsonapi in less than 60 ms' do
      movies = 1000.times.map { |_i| movie }
      expect { MovieSerializer.new(movies).serialized_json }.to perform_under(60).ms
    end

    it 'should create a hash of 1000 records with includes and meta in less than 75 ms' do
      count = 1000
      movies = count.times.map { |_i| movie }
      options = {}
      options[:meta] = { total: count }
      options[:include] = [:actors]
      expect { MovieSerializer.new(movies, options).serializable_hash }.to perform_under(75).ms
    end

    it 'should serialize 1000 records to jsonapi with includes and meta in less than 75 ms' do
      count = 1000
      movies = count.times.map { |_i| movie }
      options = {}
      options[:meta] = { total: count }
      options[:include] = [:actors]
      expect { MovieSerializer.new(movies, options).serialized_json }.to perform_under(75).ms
    end
  end

  def print_stats(message, count, ams_time, our_time)
    format = '%-15s %-10s %s'
    puts ''
    puts message
    puts format(format, 'Serializer', 'Records', 'Time')
    puts format(format, 'AMS serializer', count, ams_time.round(2).to_s + ' ms')
    puts format(format, 'Fast serializer', count, our_time.round(2).to_s + ' ms')
  end

  def run_hash_benchmark(message, movie_count, our_serializer, ams_serializer)
    our_time = Benchmark.measure { our_hash = our_serializer.serializable_hash }.real * 1000
    ams_time = Benchmark.measure { ams_hash = ams_serializer.as_json }.real * 1000
    print_stats(message, movie_count, ams_time, our_time)
  end

  def run_json_benchmark(message, movie_count, our_serializer, ams_serializer)
    our_json = nil
    ams_json = nil
    our_time = Benchmark.measure { our_json = our_serializer.serialized_json }.real * 1000
    ams_time = Benchmark.measure { ams_json = ams_serializer.to_json }.real * 1000
    print_stats(message, movie_count, ams_time, our_time)
    return our_json, ams_json
  end

  context 'when comparing with AMS 0.10.x' do
    [1, 25, 250, 1000].each do |movie_count|
      speed_factor = 25
      it "should serialize #{movie_count} records atleast #{speed_factor} times faster than AMS" do
        ams_movies = build_ams_movies(movie_count)
        movies = build_movies(movie_count)
        our_serializer = MovieSerializer.new(movies)
        ams_serializer = ActiveModelSerializers::SerializableResource.new(ams_movies)

        message = "Serialize to JSON string #{movie_count} records"
        our_json, ams_json = run_json_benchmark(message, movie_count, our_serializer, ams_serializer)

        message = "Serialize to Ruby Hash #{movie_count} records"
        run_hash_benchmark(message, movie_count, our_serializer, ams_serializer)

        expect(our_json.length).to eq ams_json.length
        expect { our_serializer.serialized_json }.to perform_faster_than { ams_serializer.to_json }.at_least(speed_factor).times
        expect { our_serializer.serializable_hash }.to perform_faster_than { ams_serializer.as_json }.at_least(speed_factor).times
      end
    end
  end

  context 'when comparing with AMS 0.10.x and with includes and meta' do
    [1, 25, 250, 1000].each do |movie_count|
      speed_factor = 25
      it "should serialize #{movie_count} records atleast #{speed_factor} times faster than AMS" do
        ams_movies = build_ams_movies(movie_count)
        movies = build_movies(movie_count)
        options = {}
        options[:meta] = { total: movie_count }
        options[:include] = [:actors, :movie_type]
        our_serializer = MovieSerializer.new(movies, options)
        ams_serializer = ActiveModelSerializers::SerializableResource.new(ams_movies, include: options[:include], meta: options[:meta])

        message = "Serialize to JSON string #{movie_count} with includes and meta"
        our_json, ams_json = run_json_benchmark(message, movie_count, our_serializer, ams_serializer)

        message = "Serialize to Ruby Hash #{movie_count} with includes and meta"
        run_hash_benchmark(message, movie_count, our_serializer, ams_serializer)

        expect(our_json.length).to eq ams_json.length
        expect { our_serializer.serialized_json }.to perform_faster_than { ams_serializer.to_json }.at_least(speed_factor).times
        expect { our_serializer.serializable_hash }.to perform_faster_than { ams_serializer.as_json }.at_least(speed_factor).times
      end
    end
  end
end
