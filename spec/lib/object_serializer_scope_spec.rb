require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  include_context 'movie class'

  context 'when setting scope' do
    context 'when not providing scope on initialization' do
      it 'returns nil when accessing scope' do
        AppName::V1::MovieSerializer.new(nil)
        expect(AppName::V1::MovieSerializer.scope).to be nil
      end
    end

    context 'when providing scope on initialization' do
      let(:account) do
        account = Account.new
        account.id = 1
        account
      end

      it 'can access scope' do
        AppName::V1::MovieSerializer.new(nil, scope: account)
        expect(AppName::V1::MovieSerializer.scope.id).to eq account.id
      end
    end
  end
end
