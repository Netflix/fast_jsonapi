# frozen_string_literal: true

require 'spec_helper'

module FastJsonapi
  module MultiToJson
    describe Result do
      it 'supports chaining of rescues' do
        expect do
          Result.new(LoadError) do
            require '1'
          end.rescue do
            require '2'
          end.rescue do
            require '3'
          end.rescue do
            '4'
          end
        end.not_to raise_error
      end
    end
  end
end
