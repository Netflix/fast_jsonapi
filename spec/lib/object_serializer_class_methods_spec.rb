require 'spec_helper'

describe FastJsonapi::ObjectSerializer do

  include_context 'movie class'

  context 'when testing class methods of object serializer' do

    before(:example) do
      MovieSerializer.relationships_to_serialize = {}
    end

    it 'returns correct relationship hash for a has_many relationship' do
      MovieSerializer.has_many :roles
      relationship = MovieSerializer.relationships_to_serialize[:roles]
      expect(relationship).to be_instance_of(Hash)
      expect(relationship.keys).to all(be_instance_of(Symbol))
      expect(relationship[:id_method_name]).to end_with '_ids'
      expect(relationship[:record_type]).to eq 'roles'.singularize.to_sym
    end

    it 'returns correct relationship hash for a has_many relationship with overrides' do
      MovieSerializer.has_many :roles, id_method_name: :roles_only_ids, record_type: :super_role
      relationship = MovieSerializer.relationships_to_serialize[:roles]
      expect(relationship[:id_method_name]).to be :roles_only_ids
      expect(relationship[:record_type]).to be :super_role
    end

    it 'returns correct relationship hash for a belongs_to relationship' do
      MovieSerializer.belongs_to :area
      relationship = MovieSerializer.relationships_to_serialize[:area]
      expect(relationship).to be_instance_of(Hash)
      expect(relationship.keys).to all(be_instance_of(Symbol))
      expect(relationship[:id_method_name]).to end_with '_id'
      expect(relationship[:record_type]).to eq 'area'.singularize.to_sym
    end

    it 'returns correct relationship hash for a belongs_to relationship with overrides' do
      MovieSerializer.has_many :area, id_method_name: :blah_id, record_type: :awesome_area, serializer: :my_area
      relationship = MovieSerializer.relationships_to_serialize[:area]
      expect(relationship[:id_method_name]).to be :blah_id
      expect(relationship[:record_type]).to be :awesome_area
      expect(relationship[:serializer]).to be :MyAreaSerializer
    end

    it 'returns correct relationship hash for a has_one relationship' do
      MovieSerializer.has_one :area
      relationship = MovieSerializer.relationships_to_serialize[:area]
      expect(relationship).to be_instance_of(Hash)
      expect(relationship.keys).to all(be_instance_of(Symbol))
      expect(relationship[:id_method_name]).to end_with '_id'
      expect(relationship[:record_type]).to eq 'area'.singularize.to_sym
    end

    it 'returns correct relationship hash for a has_one relationship with overrides' do
      MovieSerializer.has_one :area, id_method_name: :blah_id, record_type: :awesome_area
      relationship = MovieSerializer.relationships_to_serialize[:area]
      expect(relationship[:id_method_name]).to be :blah_id
      expect(relationship[:record_type]).to be :awesome_area
    end

    it 'returns serializer name correctly with namespaces' do
      AppName::V1::MovieSerializer.has_many :area, id_method_name: :blah_id
      relationship = AppName::V1::MovieSerializer.relationships_to_serialize[:area]
      expect(relationship[:serializer]).to be :'AppName::V1::AreaSerializer'
    end

    it 'sets the correct transform_method when use_hyphen is used' do
      MovieSerializer.use_hyphen
      warning_message = 'DEPRECATION WARNING: use_hyphen is deprecated and will be removed from fast_jsonapi 2.0 use (set_key_transform :dash) instead'
      expect { MovieSerializer.use_hyphen }.to output.to_stderr
      expect(MovieSerializer.instance_variable_get(:@transform_method)).to eq :dasherize
    end
  end

end
