# query-perf

Tool for profiling ES query performance. Based on real correlation id queries. Evaluates the same queries against ES5 and ES7 for comparison.

## Configuration

Set up environment variables pointing to the elasticsearch clusters including credentials:

```
export ELASTICSEARCH_URL_ES5=...
export ELASTICSEARCH_URL_ES7=...
```

## Run

```
bundle exec ruby run.rb
bundle exec ruby run.rb --window 1 --correlation-ids 1 --correlation-query 'pubsub-rails-inf-gprd-*'
```
