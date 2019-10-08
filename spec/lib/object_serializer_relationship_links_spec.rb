require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  include_context 'movie class'

  context "params option" do
    let(:hash) { serializer.serializable_hash }

    context "generating links for a serializer relationship" do
      let(:params) { {  } }
      let(:options_with_params) { { params: params } }
      let(:relationship_url) { "http://movies.com/#{movie.id}/relationships/actors" }
      let(:related_url) { "http://movies.com/movies/#{movie.name.parameterize}/actors/" }

      before(:context) do
        class MovieSerializer
          has_many :actors, lazy_load_data: false, links: {
            self:    :actors_relationship_url,
            related: -> (object, params = {}) {
              "#{params.has_key?(:secure) ? "https" : "http"}://movies.com/movies/#{object.name.parameterize}/actors/"
            }
          }
        end
      end

      context "with a single record" do
        let(:serializer) { MovieSerializer.new(movie, options_with_params) }
        let(:links) { hash[:data][:relationships][:actors][:links] }

        it "handles relationship links that call a method" do
          expect(links).to be_present
          expect(links[:self]).to eq(relationship_url)
        end

        it "handles relationship links that call a proc" do
          expect(links).to be_present
          expect(links[:related]).to eq(related_url)
        end

        context "with serializer params" do
          let(:params) { { secure: true } }
          let(:secure_related_url) { related_url.gsub("http", "https") }

          it "passes the params to the link serializer correctly" do
            expect(links).to be_present
            expect(links[:related]).to eq(secure_related_url)
          end
        end
      end

    end

    context "lazy loading relationship data" do
      before(:context) do
        class LazyLoadingMovieSerializer < MovieSerializer
          has_many :actors, lazy_load_data: true, links: {
            related: :actors_relationship_url
          }
        end
      end

      let(:serializer) { LazyLoadingMovieSerializer.new(movie) }
      let(:actor_hash) { hash[:data][:relationships][:actors] }

      it "does not include the :data key" do
        expect(actor_hash).to be_present
        expect(actor_hash).not_to have_key(:data)
      end
    end

    context "including lazy loaded relationships" do
      before(:context) do
        class LazyLoadingMovieSerializer < MovieSerializer
          has_many :actors, lazy_load_data: true, links: {
            related: :actors_relationship_url
          }
        end
      end

      let(:serializer) { LazyLoadingMovieSerializer.new(movie, include: [:actors]) }
      let(:actor_hash) { hash[:data][:relationships][:actors] }

      it "includes the :data key" do
        expect(actor_hash).to be_present
        expect(actor_hash).to have_key(:data)
      end
    end

    context "relationship links defined by a method on the object" do
      before(:context) do
        class Movie
          def relationship_links
            { self: "http://movies.com/#{id}/relationships/actors" }
          end
        end

        class LinksPassingMovieSerializer < MovieSerializer
          has_many :actors, links: :relationship_links
        end
      end

      let(:serializer) { LinksPassingMovieSerializer.new(movie) }
      let(:links) { hash[:data][:relationships][:actors][:links] }
      let(:relationship_url) { "http://movies.com/#{movie.id}/relationships/actors" }

      it "generates relationship links in the object" do
        expect(links).to be_present
        expect(links[:self]).to eq(relationship_url)
      end
    end
  end
end
