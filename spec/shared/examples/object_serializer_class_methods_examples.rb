RSpec.shared_examples 'returning correct relationship hash' do |serializer, id_method_name, record_type|
  it 'returns correct relationship hash' do
    expect(relationship).to be_instance_of(Hash)
    expect(relationship.keys).to all(be_instance_of(Symbol))
    expect(relationship[:serializer]).to be serializer
    expect(relationship[:id_method_name]).to be id_method_name
    expect(relationship[:record_type]).to be record_type
  end
end
