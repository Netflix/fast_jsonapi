require 'primalize/jsonapi'

RSpec.shared_context 'primalize movie class' do
  before :context do

    class PrimalizeMovieSerializer < Primalize::JSONAPI[Movie]
      attributes(
        name: string,
        release_year: optional(integer),
      )

      has_many(:actors) { PrimalizeActorSerializer }
      has_one(:owner) { PrimalizeUserSerializer }
      has_one(:movie_type) { PrimalizeMovieTypeSerializer }
    end

    class PrimalizeActorSerializer < Primalize::JSONAPI[Actor]
      attributes(
        name: string,
        email: string,
      )
    end

    class PrimalizeUserSerializer < Primalize::JSONAPI[User]
      attributes(name: string)
    end

    class PrimalizeMovieTypeSerializer < Primalize::JSONAPI[MovieType]
      attributes(name: string)
    end
  end

  after :context do
    %w(
      PrimalizeMovieSerializer
      PrimalizeActorSerializer
      PrimalizeUserSerializer
      PrimalizeMovieSerializer
    ).each do |klass_name|
      Object.send(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end
end
