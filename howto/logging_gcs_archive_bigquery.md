# Loading StackDriver archives from Google Cloud Storage (GCS) into BiqQuery

## Summary

Searching older logs requires loading from line-delimited JSON files stored
in GCS into another tool. In order to load a BigQuery table from a
StackDriver produced log archive, a schema must be defined using `RECORD`
types for the nested JSON elements.

### Why

 * You need to query logs older than 30 days
 * You need aggregate operators, and eventually 
   * summarized export of results
   * visualization

### What

Logs that come in to StackDriver (see [logging.md](logging.md)) are also sent
to Google Cloud Storage in batches using an export sink. After 30 days, the
log messages are expired in StackDriver, but remain in GCS.

# How

## Using the UI

These instructions are similiar in both the new style (within `console.cloud.google.com`)
and the old style (external page), but the screen shots may appear with
differing styles.

1. Create a dataset if necessary.
2. Click on a control to "Add a new table"
3. Choose "Google Cloud Storage" with "JSON (Newline Delimted)" as the `Source data`.

![source data](../img/create_table_source.png)

4. Unselect "Auto detect Schema and input parameters" if selected.
5. Add records for fields, using `RECORD` type for nested fields and adding
   subfields using the `+` on the parent record.  It should look something like this:

![record type](../img/bigquery_schema_record.png)

6. In `Advanced options`, check `Ignore unknown values`
7. If data to be imported is large, consider whether partioning will be necessary.
   1. Add `timestamp` field of type `TIMESTAMP`
   2. In `Advanced options`, select it as the partitioning field:

![partition by timestamp](../img/bigquery_table_partition.png)

8. Create the table.  If everything is right, a background job will run to
load the data into the new table.

## Alternative: Starting from an existing schema

To save time and increase usability, the text version of a table schema can be
dumped with `bq`:

```
  $ bq show --schema --format=prettyjson myproject:myhaproxy.haproxy > haproxy_schema.json 
```

The result can be copied and pasted into BigQuery by selecting `Edit as text`
when creating the schema.

Contribute changes or new schemas back to [logging_bigquery_schemas](../logging_bigquery_schemas).

# TODO

 * It's probably possible to perform the above tasks with the `bq` command line.