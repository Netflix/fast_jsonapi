require "spec_helper"

describe FastJsonapi::ObjectSerializer do
  include_context "movie class"

  let(:fields) do
    {
      movie: %i[name actors advertising_campaign],
      actor: %i[name agency]
    }
  end

  it "only returns specified fields and relationships" do
    hash = MovieSerializer.new(movie, fields: fields).serializable_hash

    expect(hash[:data].keys.sort).to eq %i[actors advertising_campaign id name]
  end

  it "only returns specified fields for included relationships" do
    hash = MovieSerializer.new(movie, fields: fields, include: %i[actors]).serializable_hash

    expect(hash[:data][:actors][0].keys.sort).to eq %i[agency id name]
  end

  it "only returns specified relationships for included relationships" do
    hash = MovieSerializer.new(movie, fields: fields, include: %i[actors advertising_campaign]).serializable_hash

    expect(hash[:data][:actors][0].keys.sort).to eq %i[agency id name]
    expect(hash[:data][:advertising_campaign].keys.sort).to eq %i[id movie name]
  end

  it "returns all fields for included relationships when no explicit fields have been specified" do
    hash = MovieSerializer.new(movie, fields: fields, include: %i[actors advertising_campaign]).serializable_hash

    expect(hash[:data][:advertising_campaign].keys.sort).to eq %i[id movie name]
  end
end
