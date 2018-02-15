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

  def print_stats(message, count, speed_factor, ams_time, fast_jsonapi_time)
    puts
    puts "#{message} (speed goal: #{speed_factor}x)"
    puts format('%-15s %-10s %-10s %s', 'Serializer', 'Records', 'Time', 'Speed Up')

    report_format = '%-15s %-10s %-10s'
    puts format(report_format, 'Fast serializer', count, fast_jsonapi_time.round(2).to_s + ' ms')

    ams_factor = ams_time / fast_jsonapi_time
    ams_result = ams_factor >= speed_factor ? '✔' : '✘'
    puts format('%-15s %-10s %-10s %sx %s', 'AMS serializer', count, ams_time.round(2).to_s + ' ms', ams_factor.round(2), ams_result)
  end

  def run_hash_benchmark(message, movie_count, speed_factor, fast_jsonapi_serializer, ams_serializer)
    fast_jsonapi_hash = nil
    ams_hash = nil

    fast_jsonapi_time = Benchmark.measure { fast_jsonapi_hash = fast_jsonapi_serializer.serializable_hash }.real * 1000
    ams_time = Benchmark.measure { ams_hash = ams_serializer.as_json }.real * 1000

    print_stats(message, movie_count, speed_factor, ams_time, fast_jsonapi_time)

    {
      fast_jsonapi: {
        hash: fast_jsonapi_hash,
        time: fast_jsonapi_time
      },
      ams: {
        hash: ams_hash,
        time: ams_time
      }
    }
  end

  def run_json_benchmark(message, movie_count, speed_factor, fast_jsonapi_serializer, ams_serializer)
    fast_jsonapi_json = nil
    ams_json = nil

    fast_jsonapi_time = Benchmark.measure { fast_jsonapi_json = fast_jsonapi_serializer.serialized_json }.real * 1000
    ams_time = Benchmark.measure { ams_json = ams_serializer.to_json }.real * 1000

    print_stats(message, movie_count, speed_factor, ams_time, fast_jsonapi_time)

    {
      fast_jsonapi: {
        json: fast_jsonapi_json,
        time: fast_jsonapi_time
      },
      ams: {
        json: ams_json,
        time: ams_time
      }
    }
  end

  context 'when comparing with AMS 0.10.x' do
    [1, 25, 250, 1000].each do |movie_count|
      speed_factor = 25
      it "should serialize #{movie_count} records atleast #{speed_factor} times faster than AMS" do
        ams_movies = build_ams_movies(movie_count)
        movies = build_movies(movie_count)

        fast_jsonapi_serializer = MovieSerializer.new(movies)
        ams_serializer = ActiveModelSerializers::SerializableResource.new(ams_movies)

        message = "Serialize to JSON string #{movie_count} records"
        json_benchmarks = run_json_benchmark(message, movie_count, speed_factor, fast_jsonapi_serializer, ams_serializer)

        message = "Serialize to Ruby Hash #{movie_count} records"
        hash_benchmarks = run_hash_benchmark(message, movie_count, speed_factor, fast_jsonapi_serializer, ams_serializer)

        # json
        expect(json_benchmarks[:fast_jsonapi][:json].length).to eq json_benchmarks[:ams][:json].length
        json_speed_up = json_benchmarks[:ams][:time] / json_benchmarks[:fast_jsonapi][:time]
        expect(json_speed_up).to be >= speed_factor

        # hash
        hash_speed_up = hash_benchmarks[:ams][:time] / hash_benchmarks[:fast_jsonapi][:time]
        expect(hash_speed_up).to be >= speed_factor
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

        fast_jsonapi_serializer = MovieSerializer.new(movies, options)
        ams_serializer = ActiveModelSerializers::SerializableResource.new(ams_movies, include: options[:include], meta: options[:meta])

        message = "Serialize to JSON string #{movie_count} with includes and meta"
        json_benchmarks = run_json_benchmark(message, movie_count, speed_factor, fast_jsonapi_serializer, ams_serializer)

        message = "Serialize to Ruby Hash #{movie_count} with includes and meta"
        hash_speed_up = run_hash_benchmark(message, movie_count, speed_factor, fast_jsonapi_serializer, ams_serializer)

        # json
        expect(json_benchmarks[:fast_jsonapi][:json].length).to eq json_benchmarks[:ams][:json].length
        json_speed_up = json_benchmarks[:ams][:time] / json_benchmarks[:fast_jsonapi][:time]
        expect(json_speed_up).to be >= speed_factor

        # hash
        hash_speed_up = hash_speed_up[:ams][:time] / hash_speed_up[:fast_jsonapi][:time]
        expect(hash_speed_up).to be >= speed_factor
      end
    end
  end
end
