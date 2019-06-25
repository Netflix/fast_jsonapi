# frozen_string_literal: true

require 'spec_helper'

describe FastJsonapi::ObjectSerializer, performance: true do
  include_context 'movie class'
  include_context 'ams movie class'
  include_context 'jsonapi movie class'
  include_context 'jsonapi-serializers movie class'

  include_context 'group class'
  include_context 'ams group class'
  include_context 'jsonapi group class'
  include_context 'jsonapi-serializers group class'

  before(:all) { GC.disable }
  after(:all) { GC.enable }

  SERIALIZERS = {
    fast_jsonapi: {
      name: 'Fast Serializer',
      hash_method: :serializable_hash,
      json_method: :serialized_json
    },
    ams: {
      name: 'AMS serializer',
      speed_factor: 25,
      hash_method: :as_json
    },
    jsonapi: {
      name: 'jsonapi-rb serializer'
    },
    jsonapis: {
      name: 'jsonapi-serializers'
    }
  }.freeze

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

  def print_stats(message, count, data)
    puts
    puts message

    name_length = SERIALIZERS.collect { |s| s[1].fetch(:name, s[0]).length }.max

    puts format("%-#{name_length + 1}s %-10s %-10s %s", 'Serializer', 'Records', 'Time', 'Speed Up')

    report_format = "%-#{name_length + 1}s %-10s %-10s"
    fast_jsonapi_time = data[:fast_jsonapi][:time]
    puts format(report_format, 'Fast serializer', count, fast_jsonapi_time.round(2).to_s + ' ms')

    data.reject { |k, _v| k == :fast_jsonapi }.each_pair do |k, v|
      t = v[:time]
      factor = t / fast_jsonapi_time

      speed_factor = SERIALIZERS[k].fetch(:speed_factor, 1)
      result = factor >= speed_factor ? '✔' : '✘'

      puts format("%-#{name_length + 1}s %-10s %-10s %sx %s", SERIALIZERS[k][:name], count, t.round(2).to_s + ' ms', factor.round(2), result)
    end
  end

  def run_hash_benchmark(message, movie_count, serializers)
    data = Hash[serializers.keys.collect { |k| [k, { hash: nil, time: nil, speed_factor: nil }] }]

    serializers.each_pair do |k, v|
      hash_method = SERIALIZERS[k].key?(:hash_method) ? SERIALIZERS[k][:hash_method] : :to_hash
      data[k][:time] = Benchmark.measure { data[k][:hash] = v.send(hash_method) }.real * 1000
    end

    print_stats(message, movie_count, data)

    data
  end

  def run_json_benchmark(message, movie_count, serializers)
    data = Hash[serializers.keys.collect { |k| [k, { json: nil, time: nil, speed_factor: nil }] }]

    serializers.each_pair do |k, v|
      ams_json = nil
      json_method = SERIALIZERS[k].key?(:json_method) ? SERIALIZERS[k][:json_method] : :to_json
      data[k][:time] = Benchmark.measure { data[k][:json] = v.send(json_method) }.real * 1000
    end

    print_stats(message, movie_count, data)

    data
  end

  context 'when comparing with AMS 0.10.x' do
    [1, 25, 250, 1000].each do |movie_count|
      it "should serialize #{movie_count} records atleast #{SERIALIZERS[:ams][:speed_factor]} times faster than AMS" do
        ams_movies = build_ams_movies(movie_count)
        movies = build_movies(movie_count)
        jsonapi_movies = build_jsonapi_movies(movie_count)
        jsonapis_movies = build_js_movies(movie_count)

        serializers = {
          fast_jsonapi: MovieSerializer.new(movies),
          ams: ActiveModelSerializers::SerializableResource.new(ams_movies),
          jsonapi: JSONAPISerializer.new(jsonapi_movies),
          jsonapis: JSONAPISSerializer.new(jsonapis_movies)
        }

        message = "Serialize to JSON string #{movie_count} records"
        json_benchmarks = run_json_benchmark(message, movie_count, serializers)

        message = "Serialize to Ruby Hash #{movie_count} records"
        hash_benchmarks = run_hash_benchmark(message, movie_count, serializers)

        # json
        expect(json_benchmarks[:fast_jsonapi][:json].length).to eq json_benchmarks[:ams][:json].length
        json_speed_up = json_benchmarks[:ams][:time] / json_benchmarks[:fast_jsonapi][:time]

        # hash
        hash_speed_up = hash_benchmarks[:ams][:time] / hash_benchmarks[:fast_jsonapi][:time]
        expect(hash_speed_up).to be >= SERIALIZERS[:ams][:speed_factor]
      end
    end
  end

  context 'when comparing with AMS 0.10.x and with includes and meta' do
    [1, 25, 250, 1000].each do |movie_count|
      it "should serialize #{movie_count} records atleast #{SERIALIZERS[:ams][:speed_factor]} times faster than AMS" do
        ams_movies = build_ams_movies(movie_count)
        movies = build_movies(movie_count)
        jsonapi_movies = build_jsonapi_movies(movie_count)
        jsonapis_movies = build_js_movies(movie_count)

        options = {}
        options[:meta] = { total: movie_count }
        options[:include] = %i[actors movie_type]

        serializers = {
          fast_jsonapi: MovieSerializer.new(movies, options),
          ams: ActiveModelSerializers::SerializableResource.new(ams_movies, include: options[:include], meta: options[:meta]),
          jsonapi: JSONAPISerializer.new(jsonapi_movies, include: options[:include], meta: options[:meta]),
          jsonapis: JSONAPISSerializer.new(jsonapis_movies, include: options[:include].map { |i| i.to_s.dasherize }, meta: options[:meta])
        }

        message = "Serialize to JSON string #{movie_count} with includes and meta"
        json_benchmarks = run_json_benchmark(message, movie_count, serializers)

        message = "Serialize to Ruby Hash #{movie_count} with includes and meta"
        hash_benchmarks = run_hash_benchmark(message, movie_count, serializers)

        # json
        expect(json_benchmarks[:fast_jsonapi][:json].length).to eq json_benchmarks[:ams][:json].length
        json_speed_up = json_benchmarks[:ams][:time] / json_benchmarks[:fast_jsonapi][:time]

        # hash
        hash_speed_up = hash_benchmarks[:ams][:time] / hash_benchmarks[:fast_jsonapi][:time]
        expect(hash_speed_up).to be >= SERIALIZERS[:ams][:speed_factor]
      end
    end
  end

  context 'when comparing with AMS 0.10.x and with polymorphic has_many' do
    [1, 25, 250, 1000].each do |group_count|
      it "should serialize #{group_count} records at least #{SERIALIZERS[:ams][:speed_factor]} times faster than AMS" do
        ams_groups = build_ams_groups(group_count)
        groups = build_groups(group_count)
        jsonapi_groups = build_jsonapi_groups(group_count)
        jsonapis_groups = build_jsonapis_groups(group_count)

        options = {}

        serializers = {
          fast_jsonapi: GroupSerializer.new(groups, options),
          ams: ActiveModelSerializers::SerializableResource.new(ams_groups),
          jsonapi: JSONAPISerializerB.new(jsonapi_groups),
          jsonapis: JSONAPISSerializerB.new(jsonapis_groups)
        }

        message = "Serialize to JSON string #{group_count} with polymorphic has_many"
        json_benchmarks = run_json_benchmark(message, group_count, serializers)

        message = "Serialize to Ruby Hash #{group_count} with polymorphic has_many"
        hash_benchmarks = run_hash_benchmark(message, group_count, serializers)

        # json
        expect(json_benchmarks[:fast_jsonapi][:json].length).to eq json_benchmarks[:ams][:json].length
        json_speed_up = json_benchmarks[:ams][:time] / json_benchmarks[:fast_jsonapi][:time]

        # hash
        hash_speed_up = hash_benchmarks[:ams][:time] / hash_benchmarks[:fast_jsonapi][:time]
        expect(hash_speed_up).to be >= SERIALIZERS[:ams][:speed_factor]
      end
    end
  end
end
