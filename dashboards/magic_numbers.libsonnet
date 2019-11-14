// A central place for managing a whole bunch of technical debt.
//
// This file stores magic numbers that we have hard-coded in our dashboards,
// rather than spread them out across many places.
//
// Normally these values are hardcoded because we cannot read these values from prometheus
// for some reason
//
// All magic number constants should have the `_magic_number` suffix for easy searching
{
  magicNumbers:: {
    gitaly_disk_sustained_read_iops_maximum_magic_number: 60000,
    gitaly_disk_sustained_read_throughput_bytes_maximum_magic_number: 1200 * 1024 * 1024,  // 1200MB/s
    gitaly_disk_sustained_write_iops_maximum_magic_number: 30000,
    gitaly_disk_sustained_write_throughput_bytes_maximum_magic_number: 400 * 1024 * 1024,  // 400MB/s

    // Technical debt: https://gitlab.com/gitlab-org/gitlab/issues/36353
    // These values should match the output of `SHOW DATABASE` in pgbouncer console!
    pgbouncer_sync_pool_size_magic_number: 50,
    pgbouncer_async_pool_size_magic_number: 75,
  },
}
