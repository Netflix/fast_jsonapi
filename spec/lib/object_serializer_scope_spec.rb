require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  include_context 'movie class'

  context "scope option" do
    let(:hash) { serializer.serializable_hash }

    before(:context) do
      class Movie
        def viewed?(user)
          user.viewed.include?(id)
        end
      end

      class MovieSerializer
        attribute :viewed do |movie, scope|
          scope ? movie.viewed?(scope) : false
        end

        attribute :unscoped_attr do |movie|
          "no-scoped-attribute"
        end
      end

      class User < Struct.new(:viewed); end
    end

    after(:context) do
      Object.send(:remove_const, User) if Object.constants.include?(User)
    end

    context "passing scope to the serializer" do
      let(:scope) { User.new([movie.id]) }
      let(:options_with_scope) { {scope: scope} }

      context "with a single record" do
        let(:serializer) { MovieSerializer.new(movie, options_with_scope) }

        it "handles scoped attributes" do
          expect(hash[:data][:attributes][:viewed]).to eq(true)
        end

        it "handles un-scoped attributes" do
          expect(hash[:data][:attributes][:unscoped_attr]).to eq("no-scoped-attribute")
        end
      end

      context "with a list of records" do
        let(:movies) { build_movies(3) }
        let(:scope) { User.new(movies.map { |m| [true, false].sample ? m.id : nil }.compact) }
        let(:serializer) { MovieSerializer.new(movies, options_with_scope) }

        it "has 3 items" do
          hash[:data].length == 3
        end

        it "handles passing scope to a list of resources" do
          scoped_attribute_values = hash[:data].map { |data| [data[:id], data[:attributes][:viewed]] }
          expected_values = movies.map { |m| [m.id.to_s, scope.viewed.include?(m.id)] }

          expect(scoped_attribute_values).to eq(expected_values)
        end

        it "handles attributes without scope should still work correctly" do
          unscoped_attribute_values = hash[:data].map { |data| data[:attributes][:unscoped_attr] }
          expected_values = (1..3).map { "no-scoped-attribute" }

          expect(unscoped_attribute_values).to eq(expected_values)
        end
      end
    end

    context "without passing a scope to the serializer" do
      context "with a single movie" do
        let(:serializer) { MovieSerializer.new(movie) }

        it "handles scoped attributes" do
          expect(hash[:data][:attributes][:viewed]).to eq(false)
        end

        it "handles un-scoped attributes" do
          expect(hash[:data][:attributes][:unscoped_attr]).to eq("no-scoped-attribute")
        end
      end

      context "with multiple movies" do
        let(:serializer) { MovieSerializer.new(build_movies(3)) }

        it "handles scoped attributes" do
          scoped_attribute_values = hash[:data].map { |data| data[:attributes][:viewed] }

          expect(scoped_attribute_values).to eq([false, false, false])
        end

        it "handles un-scoped attributes" do
          unscoped_attribute_values = hash[:data].map { |data| data[:attributes][:unscoped_attr] }
          expected_attribute_values = (1..3).map { "no-scoped-attribute" }

          expect(unscoped_attribute_values).to eq(expected_attribute_values)
        end
      end
    end
  end
end
