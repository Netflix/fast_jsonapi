# Fast JSON API

[![Build Status](https://travis-ci.org/Netflix/fast_jsonapi.svg?branch=master)](https://travis-ci.org/Netflix/fast_jsonapi)

A lightning fast [JSON:API](http://jsonapi.org/) serializer for Ruby Objects.

# Performance Comparison

We compare serialization times with Active Model Serializer as part of RSpec performance tests included on this library. We want to ensure that with every change on this library, serialization time is at least `25 times` faster than Active Model Serializers on up to current benchmark of 1000 records.

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
  * [Model Definition](#model-definition)
  * [Serializer Definition](#serializer-definition)
  * [Object Serialization](#object-serialization)
  * [Compound Document](#compound-document)
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
    "id": "232",
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
### Compound Document

Support for top-level included member through ` options[:include] `.

```ruby
options = {}
options[:meta] = { total: 2 }
options[:include] = [:actors]
MovieSerializer.new([movie, movie], options).serialized_json
```

### Collection Serialization

```ruby
options[:meta] = { total: 2 }
hash = MovieSerializer.new([movie, movie], options).serializable_hash
json_string = MovieSerializer.new([movie, movie], options).serialized_json
```

### Caching

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
cache_options | Hash to enable caching and set cache length | ```cache_options enabled: true, cache_length: 12.hours```
id_method_name | Set custom method name to get ID of an object | ```has_many :locations, id_method_name: :place_ids ```
object_method_name | Set custom method name to get related objects | ```has_many :locations, object_method_name: :places ```
record_type | Set custom Object Type for a relationship | ```belongs_to :owner, record_type: :user```
serializer | Set custom Serializer for a relationship | ```has_many :actors, serializer: :custom_actor```


## Contributing
Please see [contribution check](https://github.com/Netflix/fast_jsonapi/blob/master/CONTRIBUTING.md) for more details on contributing

### Running Tests
We use [RSpec](http://rspec.info/) for testing. We have unit tests, functional tests and performance tests. To run tests use the following command:

```bash
rspec
```

### We're Hiring!

Join the Netflix Studio Engineering team and help us build gems like this!

* [Senior Ruby Engineer](https://jobs.netflix.com/jobs/864893)
* [Senior Platform Engineer](https://jobs.netflix.com/jobs/865783)
