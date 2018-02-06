# Performance using Fast JSON API

We have been getting a few questions on Github about [Fast JSON API’s](https://github.com/Netflix/fast_jsonapi) performance statistics and the methodology used to measure the performance. This article is an attempt at addressing this aspect of the gem.  

## Prologue

With use cases like infinite scroll on complex models and bulk update on index pages, we started observing performance degradation on our Rails APIs. Our first step was to enable instrumentation and then tune for performance. We realized that, on average, more than 50% of the time was being spent on AMS serialization. At the same time, we had a couple of APIs that were simply proxying requests on top of a non-Rails, non-JSON API endpoint. Guess what? The non-Rails endpoints were giving us serialized JSON back in a fraction of the time spent by AMS.

This led us to explore AMS documentation in depth in an effort to try a variety of techniques such as caching, using OJ for JSON string generation etc. It didn’t yield the consistent results we were hoping to get. We loved the developer experience of using AMS, but wanted better performance for our use cases.

We came up with patterns that we can rely upon such as:

* We always use [JSON:API](http://jsonapi.org/) for our APIs
* We almost always serialize a homogenous list of objects (Example: An array of movies)

On the other hand:

* AMS is designed to serialize JSON in several different formats, not just JSON:API
* AMS can also handle lists that are not homogenous

This led us to build our own object serialization library that would be faster because it would be tailored to our requirements. The usage of fast_jsonapi internally on production environments resulted in significant performance gains.

## Benchmark Setup

The benchmark setup is simple with classes for ``` Movie, Actor, MovieType, User ``` on ```movie_context.rb``` for fast_jsonapi serializers and on ```ams_context.rb``` for AMS serializers. We benchmark the serializers with ```1, 25, 250, 1000``` movies, then we output the result. We also ensure that JSON string output is equivalent to ensure neither library is doing excess work compared to the other. Please checkout [object_serializer_performance_spec](https://github.com/Netflix/fast_jsonapi/blob/master/spec/lib/object_serializer_performance_spec.rb).

## Benchmark Results

We benchmarked results for creating a Ruby Hash. This approach removes the effect of chosen JSON string generation engines like OJ, Yajl etc. Benchmarks indicate that fast_jsonapi consistently performs around ```25 times``` faster than AMS in generating a ruby hash.

We applied a similar benchmark on the operation to serialize the objects to a JSON string. This approach helps with ensuring some important criterias, such as:

* OJ is used as the JSON engine for benchmarking both AMS and fast_jsonapi
* The benchmark is easy to understand
* The benchmark helps to improve performance
* The benchmark influences design decisions for the gem  

This gem is currently used in several APIs at Netflix and has reduced the response times by more than half on many of these APIs. We truly appreciate the Ruby and Rails communities and wanted to contribute in an effort to help improve the performance of your APIs too.

## Epilogue

[Fast JSON API](https://github.com/Netflix/fast_jsonapi) is not a replacement for AMS. AMS is a great gem, and it does many things and is very flexible. We still use it for non JSON:API serialization and deserialization. What started off as an internal performance exercise evolved into fast_jsonapi and created an opportunity to give something back to the awesome **Ruby and Rails communities**.

We are excited to share it with all of you since we believe that there will be **no** end to this need for speed on APIs. :)
