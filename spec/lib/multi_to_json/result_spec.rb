require "spec_helper"

module FastJsonapi
  module MultiToJson
    describe Result do
      it "supports chaining of rescues" do
        expect do
          Result.new(LoadError) { require "1" }
                .rescue { require "2" }
                .rescue { require "3" }
                .rescue { require "4" }
        end.not_to raise_error
      end
    end
  end
end
