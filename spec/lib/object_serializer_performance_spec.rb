require 'spec_helper'

describe FastJsonapi::ObjectSerializer, performance: true do
  include_context 'movie class'
  include_context 'ams movie class'
  include_context 'jsonapi movie class'

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

  def print_stats(message, count, ams_time, jsonapi_time, our_time)
    format = '%-15s %-10s %s'
    puts ''
    puts message
    puts format(format, 'Serializer', 'Records', 'Time')
    puts format(format, 'AMS serializer', count, ams_time.round(2).to_s + ' ms')
    puts format(format, 'jsonapi-rb serializer', count, jsonapi_time.round(2).to_s + ' ms')
    puts format(format, 'Fast serializer', count, our_time.round(2).to_s + ' ms')
  end

  def run_hash_benchmark(message, movie_count, our_serializer, ams_serializer, jsonapi_serializer)
    our_time = Benchmark.measure { our_hash = our_serializer.serializable_hash }.real * 1000
    ams_time = Benchmark.measure { ams_hash = ams_serializer.as_json }.real * 1000
    jsonapi_time = Benchmark.measure { ams_hash = jsonapi_serializer.to_hash }.real * 1000

    print_stats(message, movie_count, ams_time, jsonapi_time, our_time)
  end

  def run_json_benchmark(message, movie_count, our_serializer, ams_serializer, jsonapi_serializer)
    our_json = nil
    ams_json = nil
    jsonapi_json = nil
    our_time = Benchmark.measure { our_json = our_serializer.serialized_json }.real * 1000
    ams_time = Benchmark.measure { ams_json = ams_serializer.to_json }.real * 1000
    jsonapi_time = Benchmark.measure { jsonapi_json = jsonapi_serializer.to_json }.real * 1000

    print_stats(message, movie_count, ams_time, jsonapi_time, our_time)
    return our_json, ams_json, jsonapi_json
  end

  context 'when comparing with AMS 0.10.x' do
    [1, 25, 250, 1000].each do |movie_count|
      speed_factor = 25
      it "should serialize #{movie_count} records atleast #{speed_factor} times faster than AMS" do
        ams_movies = build_ams_movies(movie_count)
        movies = build_movies(movie_count)
        jsonapi_movies = build_jsonapi_movies(movie_count)
        our_serializer = MovieSerializer.new(movies)
        ams_serializer = ActiveModelSerializers::SerializableResource.new(ams_movies)
        jsonapi_serializer = JSONAPISerializer.new(jsonapi_movies)

        message = "Serialize to JSON string #{movie_count} records"
        our_json, ams_json, jsonapi_json = run_json_benchmark(message, movie_count, our_serializer, ams_serializer, jsonapi_serializer)

        message = "Serialize to Ruby Hash #{movie_count} records"
        run_hash_benchmark(message, movie_count, our_serializer, ams_serializer, jsonapi_serializer)

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
        jsonapi_movies = build_jsonapi_movies(movie_count)
        options = {}
        options[:meta] = { total: movie_count }
        options[:include] = [:actors, :movie_type]
        our_serializer = MovieSerializer.new(movies, options)
        ams_serializer = ActiveModelSerializers::SerializableResource.new(ams_movies, include: options[:include], meta: options[:meta])
        jsonapi_serializer = JSONAPISerializer.new(jsonapi_movies, include: options[:include], meta: options[:meta])

        message = "Serialize to JSON string #{movie_count} with includes and meta"
        our_json, ams_json = run_json_benchmark(message, movie_count, our_serializer, ams_serializer, jsonapi_serializer)

        message = "Serialize to Ruby Hash #{movie_count} with includes and meta"
        run_hash_benchmark(message, movie_count, our_serializer, ams_serializer, jsonapi_serializer)

        expect(our_json.length).to eq ams_json.length
        expect { our_serializer.serialized_json }.to perform_faster_than { ams_serializer.to_json }.at_least(speed_factor).times
        expect { our_serializer.serializable_hash }.to perform_faster_than { ams_serializer.as_json }.at_least(speed_factor).times
      end
    end
  end

  context 'when comparing with AMS 0.10.x' do
    include_context 'heterogeneous associations benchmark classes'

    %w(homogeneous_has_one_with_id homogeneous_has_one heterogeneous_has_one heterogeneous_has_many
    homogeneous_has_many homogeneous_has_many_with_ids).each do |case_name|
      speed_factor = 25
      case_name_segments = case_name.split '_'
      case_humanized_name = "#{case_name_segments.slice(0, 3).join(' ')} association"
      case_humanized_name << ' with association_id' if case_name =~ /with_id/i
      case_humanized_name << 's' if case_name =~ /many/i

      context "with #{case_humanized_name}" do
        [1, 25, 250, 1000].each do |object_count|
          it "serializes #{object_count} records at least #{speed_factor} times faster than AMS" do
            test_objects = send "build_#{case_name}_objects".to_sym, object_count

            association_kind = (case_name =~ /has_many/i ? 'has_many' : 'has_one').classify
            fast_jsonapi_serializer_name = "#{case_name.classify.gsub /WithId(s?)/, ''}Serializer"
            active_model_serializer_name = "AMS#{association_kind}Serializer"

            our_serializer = fast_jsonapi_serializer_name.constantize.new(test_objects, {})
            ams_serializer = ActiveModelSerializers::SerializableResource.new(test_objects, each_serializer: active_model_serializer_name.constantize)
            jsonapi_serializer = JSONAPIHeterogeneousAssociationsSerializer.new(test_objects)

            message = "Serialize to JSON string #{object_count} with #{case_name.humanize}"
            our_json, ams_json, jsonapi_json = run_json_benchmark(message, object_count, our_serializer, ams_serializer, jsonapi_serializer)

            message = "Serialize to Ruby Hash #{object_count} with #{case_name.humanize}"
            run_hash_benchmark(message, object_count, our_serializer, ams_serializer, jsonapi_serializer)

            expect(our_json.length).to eq ams_json.length
            expect { our_serializer.serialized_json }.to perform_faster_than { ams_serializer.to_json }.at_least(speed_factor).times
            expect { our_serializer.serializable_hash }.to perform_faster_than { ams_serializer.as_json }.at_least(speed_factor).times
          end
        end
      end
    end
  end
end
