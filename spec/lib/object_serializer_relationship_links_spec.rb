require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  include_context 'movie class'

  context "params option" do
    let(:hash) { serializer.serializable_hash }

    before(:context) do
      class MovieSerializer
        has_many :actors, links: {
          self:    :actors_relationship_url,
          related: -> (object, params = {}) {
            "#{params.has_key?(:secure) ? "https" : "http"}://movies.com/movies/#{object.name.parameterize}/actors/"
          }
        }
      end
    end

    context "generating links for a serializer relationship" do
      let(:params) { {  } }
      let(:options_with_params) { { params: params } }
      let(:relationship_url) { "http://movies.com/#{movie.id}/relationships/actors" }
      let(:related_url) { "http://movies.com/movies/#{movie.name.parameterize}/actors/" }

      context "with a single record" do
        let(:serializer) { MovieSerializer.new(movie, options_with_params) }
        let(:links) { hash.dig(:data, :relationships, :actors, :links) }

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
  end
end
