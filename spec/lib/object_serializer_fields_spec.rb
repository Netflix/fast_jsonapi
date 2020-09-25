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

  it 'returns no fields when none are specified' do
    hash = MovieSerializer.new(movie, fields: { movie: [] }).serializable_hash

    expect(hash[:data][:attributes].keys).to eq []
  end

  it 'returns no relationships when none are specified' do
    hash = MovieSerializer.new(movie, fields: { movie: [] }).serializable_hash

    expect(hash[:data][:relationships].keys).to eq []
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

  context 'with no included fields specified' do
    let(:fields) do
      {
        movie: %i[name actors advertising_campaign],
        actor: []
      }
    end

    it 'returns no fields for included relationships when none are specified' do
      hash = MovieSerializer.new(movie, fields: fields, include: %i[actors advertising_campaign]).serializable_hash

      expect(hash[:included][2][:attributes].keys).to eq []
    end

    it 'returns no relationships when none are specified' do
      hash = MovieSerializer.new(movie, fields: fields, include: %i[actors advertising_campaign]).serializable_hash

      expect(hash[:included][2][:relationships].keys).to eq []
    end
  end
end
