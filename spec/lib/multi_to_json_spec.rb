require 'spec_helper'

describe FastJsonapi::MultiToJson do
  include_context 'movie class'

  describe 'self.to_json' do
    subject { FastJsonapi::MultiToJson.to_json movie }

    it { is_expected.to eq("{\"id\":232,\"name\":\"test movie\",\"actor_ids\":[1,2,3],\"owner_id\":3,\"movie_type_id\":1}") }
  end
end
