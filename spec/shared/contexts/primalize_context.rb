require 'primalize'

RSpec.shared_context 'primalize movie class' do
  before :context do

    class PrimalizeMovieSerializer < Primalize::Single
      attributes(
        id: integer,
        name: string,
        release_year: optional(integer),
        actor_ids: array(integer),
        owner_id: integer,
        movie_type_id: integer,
      )
    end

    class PrimalizeActorSerializer < Primalize::Single
      attributes(
        id: integer,
        name: string,
        email: string,
      )
    end

    class PrimalizeUserSerializer < Primalize::Single
      attributes(id: integer, name: string)
    end

    class PrimalizeMovieTypeSerializer < Primalize::Single
      attributes(id: integer, name: string)
    end

    class PrimalizeMoviesResponse < Primalize::Many
      attributes(
        movies: enumerable(PrimalizeMovieSerializer),
        actors: enumerable(PrimalizeActorSerializer),
        users: enumerable(PrimalizeUserSerializer),
        movie_types: enumerable(PrimalizeMovieTypeSerializer),
      )
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
