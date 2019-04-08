require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  class Author
    attr_accessor :id, :name
  end

  class Book
    attr_accessor :id, :name, :authors, :references

    def author_ids
      authors.map(&:id)
    end
  end

  class Song
    attr_accessor :id, :name, :artist
  end

  class BookSerializer
    include FastJsonapi::ObjectSerializer
    attributes :name
    set_key_transform :dash
    has_many :authors, pluralize_type: true
    has_many :references, polymorphic: true, pluralize_type: true
    pluralize_type true
  end

  let(:book) do
    book = Book.new
    book.id = 1
    book.name = 'Monstrous Regiment'
    book
  end

  let(:author) do
    author = Author.new
    author.id = 1
    author.name = 'Terry Pratchett'
    author
  end

  let(:song) do
    song = Song.new
    song.id = 1
    song.name = 'Sweet Polly Oliver'
    song
  end

  context 'when serializing id and type of polymorphic relationships' do
    it 'should return correct type when transform_method is specified' do
      book.authors = [author]
      book.references = [song]
      book_hash = BookSerializer.new(book).to_hash
      record_type = book_hash[:data][:relationships][:authors][:data][0][:type]
      expect(record_type).to eq 'authors'.to_sym
      record_type = book_hash[:data][:relationships][:references][:data][0][:type]
      expect(record_type).to eq 'songs'.to_sym
    end
  end
end
