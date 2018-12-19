require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  include_context 'movie class'

  let(:fields) do
    {
      movie: %i[name actors advertising_campaign],
      actor: %i[name agency]
    }
  end

  it 'only returns specified fields' do
    hash = MovieSerializer.new(movie, fields: fields).serializable_hash

    expect(hash[:data][:attributes].keys.sort).to eq %i[name]
  end

  it 'only returns specified relationships' do
    hash = MovieSerializer.new(movie, fields: fields).serializable_hash

    expect(hash[:data][:relationships].keys.sort).to eq %i[actors advertising_campaign]
  end

  it 'only returns specified fields for included relationships' do
    hash = MovieSerializer.new(movie, fields: fields, include: %i[actors]).serializable_hash

    expect(hash[:included].first[:attributes].keys.sort).to eq %i[name]
  end

  it 'only returns specified relationships for included relationships' do
    hash = MovieSerializer.new(movie, fields: fields, include: %i[actors advertising_campaign]).serializable_hash

    expect(hash[:included].first[:relationships].keys.sort).to eq %i[agency]
  end

  it 'returns all fields for included relationships when no explicit fields have been specified' do
    hash = MovieSerializer.new(movie, fields: fields, include: %i[actors advertising_campaign]).serializable_hash

    expect(hash[:included][3][:attributes].keys.sort).to eq %i[id name]
  end

  it 'returns all fields for included relationships when no explicit fields have been specified' do
    hash = MovieSerializer.new(movie, fields: fields, include: %i[actors advertising_campaign]).serializable_hash

    expect(hash[:included][3][:relationships].keys.sort).to eq %i[movie]
  end

  describe 'preset_fields' do
    let(:movie) do
      m = Movie.new
      m.id = 232
      m.name = 'test movie'
      m.actor_ids = [1, 2, 3]
      m.owner_id = 3
      m.movie_type_id = 1
      m.release_year = 2018
      m
    end

    class MovieWithPresetSerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie
      # director attr is not mentioned intentionally
      attributes :name, :release_year
      has_many :actors
      belongs_to :owner, record_type: :user do |object, params|
        object.owner
      end
      belongs_to :movie_type
      has_one :advertising_campaign

      preset_fields :summary, :name, :release_year, :movie_type
    end

    it 'include only summary preset' do
      data = MovieWithPresetSerializer.new(movie, preset_fields: :summary).serializable_hash[:data]
      expect(data[:attributes]).to eq name: 'test movie', release_year: 2018
      expect(data[:relationships].keys).to eq [:movie_type]
    end
  end
end
