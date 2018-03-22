require 'spec_helper'

describe FastJsonapi::ObjectSerializer do

  include_context 'movie class'

  describe '#has_many' do
    subject(:relationship) { serializer.relationships_to_serialize[:roles] }

    before do
      serializer.has_many *children
    end

    context 'with namespace' do
      let(:serializer) { AppName::V1::MovieSerializer }
      let(:children) { [:roles] }

      context 'with overrides' do
        let(:children) { [:roles, id_method_name: :roles_only_ids, record_type: :super_role] }

        it_behaves_like 'returning correct relationship hash', :'AppName::V1::RoleSerializer', :roles_only_ids, :super_role
      end

      context 'without overrides' do
        let(:children) { [:roles] }

        it_behaves_like 'returning correct relationship hash', :'AppName::V1::RoleSerializer', :role_ids, :role
      end
    end

    context 'without namespace' do
      let(:serializer) { MovieSerializer }

      context 'with overrides' do
        let(:children) { [:roles, id_method_name: :roles_only_ids, record_type: :super_role] }

        it_behaves_like 'returning correct relationship hash', :'RoleSerializer', :roles_only_ids, :super_role
      end

      context 'without overrides' do
        let(:children) { [:roles] }

        it_behaves_like 'returning correct relationship hash', :'RoleSerializer', :role_ids, :role
      end
    end
  end

  describe '#belongs_to' do
    subject(:relationship) { MovieSerializer.relationships_to_serialize[:area] }

    before do
      MovieSerializer.belongs_to *parent
    end

    context 'with overrides' do
      let(:parent) { [:area, id_method_name: :blah_id, record_type: :awesome_area, serializer: :my_area] }

      it_behaves_like 'returning correct relationship hash', :'MyAreaSerializer', :blah_id, :awesome_area
    end

    context 'without overrides' do
      let(:parent) { [:area] }

      it_behaves_like 'returning correct relationship hash', :'AreaSerializer', :area_id, :area
    end
  end

  describe '#has_one' do
    subject(:relationship) { MovieSerializer.relationships_to_serialize[:area] }

    before do
      MovieSerializer.has_one *partner
    end

    context 'with overrides' do
      let(:partner) { [:area, id_method_name: :blah_id, record_type: :awesome_area, serializer: :my_area] }

      it_behaves_like 'returning correct relationship hash', :'MyAreaSerializer', :blah_id, :awesome_area
    end

    context 'without overrides' do
      let(:partner) { [:area] }

      it_behaves_like 'returning correct relationship hash', :'AreaSerializer', :area_id, :area
    end
  end

  describe '#use_hyphen' do
    subject { MovieSerializer.use_hyphen }

    it 'sets the correct transform_method when use_hyphen is used' do
      warning_message = "DEPRECATION WARNING: use_hyphen is deprecated and will be removed from fast_jsonapi 2.0 use (set_key_transform :dash) instead\n"
      expect { subject }.to output(warning_message).to_stderr
      expect(MovieSerializer.instance_variable_get(:@transform_method)).to eq :dasherize
    end
  end
end
