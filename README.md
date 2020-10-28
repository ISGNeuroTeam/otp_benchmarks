###### dataset/benchmark.json.gz
Contain the packed source dataframe.

###### dataset/benchmark_index_single_bucket_single_parquet_file.tar.gz
Contain the packed index _**benchmark_index_single_bucket_single_parquet_file**_ for platform, containing 1 parquet file in one bucket.

###### dataset/benchmark_index_many_bucket_many_parquet_file.tar.gz
Contain the packed index _**benchmark_index_many_bucket_many_parquet_file**_ for platform, containing 150k buckets with one parquet file.

### OTL Query
```text
Time for configuration
    2cpu driver (4GB)
    1 workers with 2 executers (2GB per executer)
    SSD NVME
```

```text
benchmark_index_single_bucket_single_parquet_file

    search index=benchmark_index_single_bucket_single_parquet_file | stats count
        ~1sec
      
    search index=benchmark_index_single_bucket_single_parquet_file "sdfsdfsdf" | stats count
        ~3sec
      
    search index=benchmark_index_single_bucket_single_parquet_file | table * | stats count 
        ~140sec
```

```text
benchmark_index_many_bucket_many_parquet_file

    otstats index=benchmark_index_many_bucket_many_parquet_file | stats count
        ~103sec
    
    otstats index=benchmark_index_many_bucket_many_parquet_file "sdfsdfsdf" | stats count
        ~182sec
    
    otstats index=benchmark_index_many_bucket_many_parquet_file | table * | stats count
        ~157sec
    
    otstats index=benchmark_index_many_bucket_many_parquet_file | head 10
        ~210sec
```

