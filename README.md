# Fast JSON API

[![Build Status](https://travis-ci.org/Netflix/fast_jsonapi.svg?branch=master)](https://travis-ci.org/Netflix/fast_jsonapi)

A lightning fast [JSON:API](http://jsonapi.org/) serializer for Ruby Objects.

# Performance Comparison

We compare serialization times with Active Model Serializer as part of RSpec performance tests included on this library. We want to ensure that with every change on this library, serialization time is at least `25 times` faster than Active Model Serializers on up to current benchmark of 1000 records. Please read the [performance document](https://github.com/Netflix/fast_jsonapi/blob/master/performance_methodology.md) for any questions related to methodology.

## Benchmark times for 250 records

```bash
$ rspec
Active Model Serializer serialized 250 records in 138.71 ms
Fast JSON API serialized 250 records in 3.01 ms
```

# Table of Contents

* [Features](#features)
* [Installation](#installation)
* [Usage](#usage)
  * [Rails Generator](#rails-generator)
  * [Model Definition](#model-definition)
  * [Serializer Definition](#serializer-definition)
  * [Object Serialization](#object-serialization)
  * [Compound Document](#compound-document)
  * [Key Transforms](#key-transforms)
  * [Collection Serialization](#collection-serialization)
  * [Caching](#caching)
  * [Params](#params)
  * [Conditional Attributes](#conditional-attributes)
  * [Conditional Relationships](#conditional-relationships)
  * [Sparse Fieldsets](#sparse-fieldsets)
* [Contributing](#contributing)


## Features

* Declaration syntax similar to Active Model Serializer
* Support for `belongs_to`, `has_many` and `has_one`
* Support for compound documents (included)
* Optimized serialization of compound documents
* Caching

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fast_jsonapi'
```

Execute:

```bash
$ bundle install
```

## Usage

### Rails Generator
You can use the bundled generator if you are using the library inside of
a Rails project:

    rails g serializer Movie name year

This will create a new serializer in `app/serializers/movie_serializer.rb`

### Model Definition

```ruby
class Movie
  attr_accessor :id, :name, :year, :actor_ids, :owner_id, :movie_type_id
end
```

### Serializer Definition

```ruby
class MovieSerializer
  include FastJsonapi::ObjectSerializer
  set_type :movie  # optional
  set_id :owner_id # optional
  attributes :name, :year
  has_many :actors
  belongs_to :owner, record_type: :user
  belongs_to :movie_type
end
```

### Sample Object

```ruby
movie = Movie.new
movie.id = 232
movie.name = 'test movie'
movie.actor_ids = [1, 2, 3]
movie.owner_id = 3
movie.movie_type_id = 1
movie
```

### Object Serialization

#### Return a hash
```ruby
hash = MovieSerializer.new(movie).serializable_hash
```

#### Return Serialized JSON
```ruby
json_string = MovieSerializer.new(movie).serialized_json
```

#### Serialized Output

```json
{
  "data": {
    "id": "3",
    "type": "movie",
    "attributes": {
      "name": "test movie",
      "year": null
    },
    "relationships": {
      "actors": {
        "data": [
          {
            "id": "1",
            "type": "actor"
          },
          {
            "id": "2",
            "type": "actor"
          }
        ]
      },
      "owner": {
        "data": {
          "id": "3",
          "type": "user"
        }
      }
    }
  }
}

```

### Key Transforms
By default fast_jsonapi underscores the key names. It supports the same key transforms that are supported by AMS. Here is the syntax of specifying a key transform

```ruby
class MovieSerializer
  include FastJsonapi::ObjectSerializer
  # Available options :camel, :camel_lower, :dash, :underscore(default)
  set_key_transform :camel
end
```
Here are examples of how these options transform the keys

```ruby
set_key_transform :camel # "some_key" => "SomeKey"
set_key_transform :camel_lower # "some_key" => "someKey"
set_key_transform :dash # "some_key" => "some-key"
set_key_transform :underscore # "some_key" => "some_key"
```

### Attributes
Attributes are defined in FastJsonapi using the `attributes` method.  This method is also aliased as `attribute`, which is useful when defining a single attribute.

By default, attributes are read directly from the model property of the same name.  In this example, `name` is expected to be a property of the object being serialized:

```ruby
class MovieSerializer
  include FastJsonapi::ObjectSerializer

  attribute :name
end
```

Custom attributes that must be serialized but do not exist on the model can be declared using Ruby block syntax:

```ruby
class MovieSerializer
  include FastJsonapi::ObjectSerializer

  attributes :name, :year

  attribute :name_with_year do |object|
    "#{object.name} (#{object.year})"
  end
end
```

The block syntax can also be used to override the property on the object:

```ruby
class MovieSerializer
  include FastJsonapi::ObjectSerializer

  attribute :name do |object|
    "#{object.name} Part 2"
  end
end
```

Attributes can also use a different name by passing the original method or accessor with a proc shortcut:

```ruby
class MovieSerializer
  include FastJsonapi::ObjectSerializer

  attributes :name

  attribute :released_in_year, &:year
end
```

### Links Per Object
Links are defined in FastJsonapi using the `link` method. By default, links are read directly from the model property of the same name. In this example, `public_url` is expected to be a property of the object being serialized.

You can configure the method to use on the object for example a link with key `self` will get set to the value returned by a method called `url` on the movie object.

You can also use a block to define a url as shown in `custom_url`. You can access params in these blocks as well as shown in `personalized_url`

```ruby
class MovieSerializer
  include FastJsonapi::ObjectSerializer

  link :public_url

  link :self, :url

  link :custom_url do |object|
    "http://movies.com/#{object.name}-(#{object.year})"
  end

  link :personalized_url do |object, params|
    "http://movies.com/#{object.name}-#{params[:user].reference_code}"
  end
end
```

#### Links on a Relationship

You can specify [relationship links](http://jsonapi.org/format/#document-resource-object-relationships) by using the `links:` option on the serializer. Relationship links in JSON API are useful if you want to load a parent document and then load associated documents later due to size constraints (see [related resource links](http://jsonapi.org/format/#document-resource-object-related-resource-links))

```ruby
class MovieSerializer
  include FastJsonapi::ObjectSerializer

  has_many :actors, links: {
    self: :url,
    related: -> (object) {
      "https://movies.com/#{object.id}/actors"
    }
  }
end
```

This will create a `self` reference for the relationship, and a `related` link for loading the actors relationship later. NB: This will not automatically disable loading the data in the relationship, you'll need to do that using the `lazy_load_data` option:

```ruby
  has_many :actors, lazy_load_data: true, links: {
    self: :url,
    related: -> (object) {
      "https://movies.com/#{object.id}/actors"
    }
  }
```

### Meta Per Resource

For every resource in the collection, you can include a meta object containing non-standard meta-information about a resource that can not be represented as an attribute or relationship.
```ruby
  meta do |movie|
    {
      years_since_release: Date.current.year - movie.year
    }
  end
end
```

### Compound Document

Support for top-level and nested included associations through ` options[:include] `.

```ruby
options = {}
options[:meta] = { total: 2 }
options[:links] = {
  self: '...',
  next: '...',
  prev: '...'
}
options[:include] = [:actors, :'actors.agency', :'actors.agency.state']
MovieSerializer.new([movie, movie], options).serialized_json
```

### Collection Serialization

```ruby
options[:meta] = { total: 2 }
options[:links] = {
  self: '...',
  next: '...',
  prev: '...'
}
hash = MovieSerializer.new([movie, movie], options).serializable_hash
json_string = MovieSerializer.new([movie, movie], options).serialized_json
```

#### Control Over Collection Serialization

You can use `is_collection` option to have better control over collection serialization.

If this option is not provided or `nil` autedetect logic is used to try understand
if provided resource is a single object or collection.

Autodetect logic is compatible with most DB toolkits (ActiveRecord, Sequel, etc.) but
**cannot** guarantee that single vs collection will be always detected properly.

```ruby
options[:is_collection]
```

was introduced to be able to have precise control this behavior

- `nil` or not provided: will try to autodetect single vs collection (please, see notes above)
- `true` will always treat input resource as *collection*
- `false` will always treat input resource as *single object*

### Caching
Requires a `cache_key` method be defined on model:

```ruby
class MovieSerializer
  include FastJsonapi::ObjectSerializer
  set_type :movie  # optional
  cache_options enabled: true, cache_length: 12.hours
  attributes :name, :year
end
```

### Params

In some cases, attribute values might require more information than what is
available on the record, for example, access privileges or other information
related to a current authenticated user. The `options[:params]` value covers these
cases by allowing you to pass in a hash of additional parameters necessary for
your use case.

Leveraging the new params is easy, when you define a custom attribute or relationship with a
block you opt-in to using params by adding it as a block parameter.

```ruby
class MovieSerializer
  include FastJsonapi::ObjectSerializer

  attributes :name, :year
  attribute :can_view_early do |movie, params|
    # in here, params is a hash containing the `:current_user` key
    params[:current_user].is_employee? ? true : false
  end

  belongs_to :primary_agent do |movie, params|
    # in here, params is a hash containing the `:current_user` key
    params[:current_user].is_employee? ? true : false
  end
end

# ...
current_user = User.find(cookies[:current_user_id])
serializer = MovieSerializer.new(movie, {params: {current_user: current_user}})
serializer.serializable_hash
```

Custom attributes and relationships that only receive the resource are still possible by defining
the block to only receive one argument.

### Conditional Attributes

Conditional attributes can be defined by passing a Proc to the `if` key on the `attribute` method. Return `true` if the attribute should be serialized, and `false` if not. The record and any params passed to the serializer are available inside the Proc as the first and second parameters, respectively.

```ruby
class MovieSerializer
  include FastJsonapi::ObjectSerializer

  attributes :name, :year
  attribute :release_year, if: Proc.new { |record|
    # Release year will only be serialized if it's greater than 1990
    record.release_year > 1990
  }

  attribute :director, if: Proc.new { |record, params|
    # The director will be serialized only if the :admin key of params is true
    params && params[:admin] == true
  }
end

# ...
current_user = User.find(cookies[:current_user_id])
serializer = MovieSerializer.new(movie, { params: { admin: current_user.admin? }})
serializer.serializable_hash
```

### Conditional Relationships

Conditional relationships can be defined by passing a Proc to the `if` key. Return `true` if the relationship should be serialized, and `false` if not. The record and any params passed to the serializer are available inside the Proc as the first and second parameters, respectively.

```ruby
class MovieSerializer
  include FastJsonapi::ObjectSerializer

  # Actors will only be serialized if the record has any associated actors
  has_many :actors, if: Proc.new { |record| record.actors.any? }

  # Owner will only be serialized if the :admin key of params is true
  belongs_to :owner, if: Proc.new { |record, params| params && params[:admin] == true }
end

# ...
current_user = User.find(cookies[:current_user_id])
serializer = MovieSerializer.new(movie, { params: { admin: current_user.admin? }})
serializer.serializable_hash
```

### Sparse Fieldsets

Attributes and relationships can be selectively returned per record type by using the `fields` option.

```ruby
class MovieSerializer
  include FastJsonapi::ObjectSerializer

  attributes :name, :year
end

serializer = MovieSerializer.new(movie, { fields: { movie: [:name] } })
serializer.serializable_hash
```

### Customizable Options

Option | Purpose | Example
------------ | ------------- | -------------
set_type | Type name of Object | ```set_type :movie ```
key | Key of Object | ```belongs_to :owner, key: :user ```
set_id | ID of Object | ```set_id :owner_id ``` or ```set_id { |record| "#{record.name.downcase}-#{record.id}" }```
cache_options | Hash to enable caching and set cache length | ```cache_options enabled: true, cache_length: 12.hours, race_condition_ttl: 10.seconds```
id_method_name | Set custom method name to get ID of an object (If block is provided for the relationship, `id_method_name` is invoked on the return value of the block instead of the resource object) | ```has_many :locations, id_method_name: :place_ids ```
object_method_name | Set custom method name to get related objects | ```has_many :locations, object_method_name: :places ```
record_type | Set custom Object Type for a relationship | ```belongs_to :owner, record_type: :user```
serializer | Set custom Serializer for a relationship | ```has_many :actors, serializer: :custom_actor``` or ```has_many :actors, serializer: MyApp::Api::V1::ActorSerializer```
polymorphic | Allows different record types for a polymorphic association | ```has_many :targets, polymorphic: true```
polymorphic | Sets custom record types for each object class in a polymorphic association | ```has_many :targets, polymorphic: { Person => :person, Group => :group }```

### Instrumentation

`fast_jsonapi` also has builtin [Skylight](https://www.skylight.io/) integration. To enable, add the following to an initializer:

```ruby
require 'fast_jsonapi/instrumentation/skylight'
```

Skylight relies on `ActiveSupport::Notifications` to track these two core methods. If you would like to use these notifications without using Skylight, simply require the instrumentation integration:

```ruby
require 'fast_jsonapi/instrumentation'
```

The two instrumented notifcations are supplied by these two constants:
* `FastJsonapi::ObjectSerializer::SERIALIZABLE_HASH_NOTIFICATION`
* `FastJsonapi::ObjectSerializer::SERIALIZED_JSON_NOTIFICATION`

It is also possible to instrument one method without the other by using one of the following require statements:

```ruby
require 'fast_jsonapi/instrumentation/serializable_hash'
require 'fast_jsonapi/instrumentation/serialized_json'
```

Same goes for the Skylight integration:
```ruby
require 'fast_jsonapi/instrumentation/skylight/normalizers/serializable_hash'
require 'fast_jsonapi/instrumentation/skylight/normalizers/serialized_json'
```

## Contributing
Please see [contribution check](https://github.com/Netflix/fast_jsonapi/blob/master/CONTRIBUTING.md) for more details on contributing

### Running Tests
We use [RSpec](http://rspec.info/) for testing. We have unit tests, functional tests and performance tests. To run tests use the following command:

```bash
rspec
```

To run tests without the performance tests (for quicker test runs):

```bash
rspec spec --tag ~performance:true
```

To run tests only performance tests:

```bash
rspec spec --tag performance:true
```

### We're Hiring!

Join the Netflix Studio Engineering team and help us build gems like this!

* [Senior Ruby Engineer](https://jobs.netflix.com/jobs/864893)
