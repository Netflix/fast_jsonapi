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
  * [Scope](#scope)
  * [Collection Serialization](#collection-serialization)
  * [Caching](#caching)
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

### Scope
Allows you to include in the serializer access to an external method.
It's intended to provide an authorization context to the serializer, so that you may use the same serializer for different outcomes.
```ruby
class MovieSerializer < ActiveModel::Serializer
  attributes :id, :name

  attribute :current_user_signed do |movie|
    return movie.signed? unless scope

    scope.admin? ? scope.admin_signed? : scope.user_signed?
  end
end
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

### Compound Document

Support for top-level included member through ` options[:include] `.

```ruby
options = {}
options[:meta] = { total: 2 }
options[:links] = {
  self: '...',
  next: '...',
  prev: '...'
}
options[:include] = [:actors]
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

### Customizable Options

Option | Purpose | Example
------------ | ------------- | -------------
set_type | Type name of Object | ```set_type :movie ```
set_id | ID of Object | ```set_id :owner_id ```
cache_options | Hash to enable caching and set cache length | ```cache_options enabled: true, cache_length: 12.hours```
id_method_name | Set custom method name to get ID of an object | ```has_many :locations, id_method_name: :place_ids ```
object_method_name | Set custom method name to get related objects | ```has_many :locations, object_method_name: :places ```
record_type | Set custom Object Type for a relationship | ```belongs_to :owner, record_type: :user```
serializer | Set custom Serializer for a relationship | ```has_many :actors, serializer: :custom_actor```
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
* [Senior Platform Engineer](https://jobs.netflix.com/jobs/865783)
