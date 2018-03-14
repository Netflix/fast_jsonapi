require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  include_context 'movie class'

  context 'when setting id' do
    subject(:serializable_hash) { MovieSerializer.new(resource).serializable_hash }

    before(:all) do
      MovieSerializer.set_id :owner_id
    end

    context 'when one record is given' do
      let(:resource) { movie }

      it 'returns correct hash which id equals owner_id' do
        expect(serializable_hash[:data][:id].to_i).to eq movie.owner_id
      end
    end

    context 'when an array of records is given' do
      let(:resource) { [movie, movie] }

      it 'returns correct hash which id equals owner_id' do
        expect(serializable_hash[:data][0][:id].to_i).to eq movie.owner_id
        expect(serializable_hash[:data][1][:id].to_i).to eq movie.owner_id
      end
    end
  end
end
