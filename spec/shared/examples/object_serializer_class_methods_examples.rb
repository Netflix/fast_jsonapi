RSpec.shared_examples "returning correct relationship hash" do |serializer, id_method_name, record_type|
  it "returns correct relationship hash" do
    expect(relationship).to be_instance_of(FastJsonapi::Relationship)
    # expect(relationship.keys).to all(be_instance_of(Symbol))
    expect(relationship.serializer).to be serializer
    expect(relationship.id_method_name).to be id_method_name
    expect(relationship.record_type).to be record_type
  end
end

RSpec.shared_examples "returning key transformed hash" do |movie_type, _, release_year|
  it "returns correctly transformed hash" do
    expect(hash[:data][0]).to have_key(release_year)
    expect(hash[:data][0][:relationships]).to have_key(movie_type)
  end
end
