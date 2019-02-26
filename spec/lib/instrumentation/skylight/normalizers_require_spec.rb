require "spec_helper"

describe FastJsonapi::ObjectSerializer do
  context "instrument", instrumentation: true do
    context "skylight" do
      # skip for normal runs because this could alter some
      # other test by inserting the instrumentation
      it "make sure requiring skylight normalizers works" do
        require "fast_jsonapi/instrumentation/skylight"
      end
    end
  end
end
