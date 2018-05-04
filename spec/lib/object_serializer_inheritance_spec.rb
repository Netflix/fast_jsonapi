require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  include_context 'movie class'

  let(:subclass_serializer) do
    Class.new(MovieSerializer) do
      attributes :director
    end
  end

  context 'when testing subclass of object serializer' do

    it 'includes parent attributes' do
      MovieSerializer.attributes_to_serialize.each do |k,v|
        expect(subclass_serializer.attributes_to_serialize[k]).to eq(v)
      end
    end

    it 'includes child attributes' do
      expect(subclass_serializer.attributes_to_serialize[:director]).to eq(:director)
    end

    it 'doesnt change parent class attributes' do
      subclass_serializer
      expect(MovieSerializer.attributes_to_serialize).not_to have_key(:director)
    end
  end
end
