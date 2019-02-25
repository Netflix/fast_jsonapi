require "spec_helper"

describe FastJsonapi::ObjectSerializer do
  include_context "movie class"

  context "params option" do
    let(:hash) { serializer.serializable_hash }

    before(:context) do
      class MovieSerializer
        has_many :agencies do |movie, params|
          movie.actors.map(&:agency) if params[:authorized]
        end

        belongs_to :primary_agency do |movie, params|
          movie.actors.map(&:agency)[0] if params[:authorized]
        end

        belongs_to :secondary_agency do |movie|
          movie.actors.map(&:agency)[1]
        end
      end
    end

    context "passing params to the serializer" do
      let(:params) { { authorized: true } }
      let(:options_with_params) { { params: params } }

      context "with a single record" do
        let(:serializer) { MovieSerializer.new(movie, options_with_params) }

        it "handles relationships that use params" do
          ids = hash[:data][:relationships][:agencies][:data].map { |a| a[:id] }
          ids.map!(&:to_i)
          expect(ids).to eq [0, 1, 2]
        end

        it "handles relationships that do not use params" do
          expect(hash[:data][:relationships][:secondary_agency][:data]).to(
            include(id: 1)
          )
        end
      end

      context "with a list of records" do
        let(:movies) { build_movies(3) }
        let(:params) { { authorized: true } }
        let(:serializer) { MovieSerializer.new(movies, options_with_params) }

        it "handles relationship params when passing params to a list of resources" do
          relationships_hashes = hash[:data].map { |a|
            a[:relationships][:agencies][:data]
          }.uniq.flatten
          expect(relationships_hashes.map { |a|
            a[:id].to_i
          }).to contain_exactly 0, 1, 2

          uniq_count = hash[:data].map { |a|
            a[:relationships][:primary_agency]
          }.uniq.count
          expect(uniq_count).to eq 1
        end

        it "handles relationships without params" do
          uniq_count = hash[:data].map { |a|
            a[:relationships][:secondary_agency]
          }.uniq.count
          expect(uniq_count).to eq 1
        end
      end
    end
  end
end
