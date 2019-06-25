# frozen_string_literal: true

require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  context 'instrument' do
    context 'skylight' do
      # skip for normal runs because this could alter some
      # other test by insterting the instrumentation
      xit 'make sure requiring skylight normalizers works' do
        require 'fast_jsonapi/instrumentation/skylight'
      end
    end
  end
end
