# frozen_string_literal: true

require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  include_context 'movie class'

  context 'params option' do
    let(:hash) { serializer.serializable_hash }

    before(:context) do
      class Movie
        def viewed?(user)
          user.viewed.include?(id)
        end
      end

      class MovieSerializer
        attribute :viewed do |movie, params|
          params ? movie.viewed?(params[:user]) : false
        end

        attribute :no_param_attribute do |_movie|
          'no-param-attribute'
        end
      end

      User = Struct.new(:viewed)
    end

    after(:context) do
      Object.send(:remove_const, User) if Object.constants.include?(User)
    end

    context 'enforces a hash only params' do
      let(:params) { User.new([]) }

      it 'fails when creating a serializer with an object as params' do
        expect(-> { MovieSerializer.new(movie, params: User.new([])) }).to raise_error(ArgumentError)
      end

      it 'succeeds creating a serializer with a hash' do
        expect(-> { MovieSerializer.new(movie, params: { current_user: User.new([]) }) }).not_to raise_error
      end
    end

    context 'passing params to the serializer' do
      let(:params) { { user: User.new([movie.id]) } }
      let(:options_with_params) { { params: params } }

      context 'with a single record' do
        let(:serializer) { MovieSerializer.new(movie, options_with_params) }

        it 'handles attributes that use params' do
          expect(hash[:data][:attributes][:viewed]).to eq(true)
        end

        it "handles attributes that don't use params" do
          expect(hash[:data][:attributes][:no_param_attribute]).to eq('no-param-attribute')
        end
      end

      context 'with a list of records' do
        let(:movies) { build_movies(3) }
        let(:user) { User.new(movies.map { |m| [true, false].sample ? m.id : nil }.compact) }
        let(:params) { { user: user } }
        let(:serializer) { MovieSerializer.new(movies, options_with_params) }

        it 'has 3 items' do
          hash[:data].length == 3
        end

        it 'handles passing params to a list of resources' do
          param_attribute_values = hash[:data].map { |data| [data[:id], data[:attributes][:viewed]] }
          expected_values = movies.map { |m| [m.id.to_s, user.viewed.include?(m.id)] }

          expect(param_attribute_values).to eq(expected_values)
        end

        it 'handles attributes without params' do
          no_param_attribute_values = hash[:data].map { |data| data[:attributes][:no_param_attribute] }
          expected_values = (1..3).map { 'no-param-attribute' }

          expect(no_param_attribute_values).to eq(expected_values)
        end
      end
    end

    context 'without passing params to the serializer' do
      context 'with a single movie' do
        let(:serializer) { MovieSerializer.new(movie) }

        it 'handles param attributes' do
          expect(hash[:data][:attributes][:viewed]).to eq(false)
        end

        it "handles attributes that don't use params" do
          expect(hash[:data][:attributes][:no_param_attribute]).to eq('no-param-attribute')
        end
      end

      context 'with multiple movies' do
        let(:serializer) { MovieSerializer.new(build_movies(3)) }

        it 'handles attributes with params' do
          param_attribute_values = hash[:data].map { |data| data[:attributes][:viewed] }

          expect(param_attribute_values).to eq([false, false, false])
        end

        it "handles attributes that don't use params" do
          no_param_attribute_values = hash[:data].map { |data| data[:attributes][:no_param_attribute] }
          expected_attribute_values = (1..3).map { 'no-param-attribute' }

          expect(no_param_attribute_values).to eq(expected_attribute_values)
        end
      end
    end
  end
end
