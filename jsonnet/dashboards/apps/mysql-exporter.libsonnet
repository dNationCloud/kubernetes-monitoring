/*
  Copyright 2020 The dNation Kubernetes Monitoring Authors. All Rights Reserved.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

/* K8s mysql exporter dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local statPanel = grafana.panel.stat;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;
local fieldOverride = grafana.panel.timeSeries.fieldOverride;

{
  grafanaDashboards+:: {
    'mysql-exporter':
      local color = $._config.grafanaDashboards.color;

      local colorOverride(alias, col) = fieldOverride.byRegexp.new(alias)
                                          + fieldOverride.byRegexp.withProperty('color', { mode: 'fixed', fixedColor: col });

      local fill0Override(alias) = fieldOverride.byRegexp.new(alias)
                                     + fieldOverride.byRegexp.withProperty('custom.fillOpacity', 0);

      local rightAxisOverride(alias) = fieldOverride.byRegexp.new(alias)
                                         + fieldOverride.byRegexp.withProperty('custom.axisPlacement', 'right');

      local promTarget(expr, legendFormat=null) =
        prometheus.withExpr(expr) + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {});

      local statBase(title, desc, expr, unit, steps) =
        statPanel.new(title)
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.panelOptions.withDescription(desc)
        + statPanel.standardOptions.withUnit(unit)
        + statPanel.standardOptions.withDecimals(0)
        + statPanel.options.withColorMode('value')
        + statPanel.options.withGraphMode('none')
        + statPanel.options.reduceOptions.withCalcs(['mean'])
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps(steps)
        + statPanel.queryOptions.withTargets([promTarget(expr, '{{instance}}')]);

      local upTimePanel = statBase('Uptime',
                                   '**Uptime**\n\nThe amount of time since the last restart of the MySQL server process.',
                                   'avg(mysql_global_status_uptime{cluster="$cluster", job=~"$job", instance=~"$instance"}) by (instance)',
                                   's',
                                   [{ color: color.red, value: null }, { color: color.orange, value: 300 }, { color: color.green, value: 3600 }]);

      local currentQPS = statBase('Current QPS',
                                  "**Current QPS**\n\nBased on the queries reported by MySQL's ``SHOW STATUS`` command, it is the number of statements executed by the server within the last second. This variable includes statements executed within stored programs, unlike the Questions variable. It does not count \n``COM_PING`` or ``COM_STATISTICS`` commands.",
                                  'avg(rate(mysql_global_status_queries{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)',
                                  'none',
                                  [{ color: color.red, value: null }, { color: color.orange, value: 35 }, { color: color.green, value: 75 }]);

      local innoDBBufferPool = statBase('InnoDB Buffer Pool',
                                        '**InnoDB Buffer Pool Size**\n\nInnoDB maintains a storage area called the buffer pool for caching data and indexes in memory.  Knowing how the InnoDB buffer pool works, and taking advantage of it to keep frequently accessed data in memory, is one of the most important aspects of MySQL tuning. The goal is to keep the working set in memory. In most cases, this should be between 60%-90% of available memory on a dedicated database host, but depends on many factors.',
                                        'avg(mysql_global_variables_innodb_buffer_pool_size{cluster="$cluster", job=~"$job", instance=~"$instance"}) by (instance)',
                                        'bytes',
                                        [{ color: color.red, value: null }, { color: color.orange, value: 90 }, { color: color.green, value: 95 }]);

      local timeSeriesBase(title, desc=null, unit=null, fillOpacity=20, calcs=['mean', 'max', 'min'], overrides=[]) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + (if desc != null then timeSeriesPanel.panelOptions.withDescription(desc) else {})
        + (if unit != null then timeSeriesPanel.standardOptions.withUnit(unit) else {})
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(fillOpacity)
        + timeSeriesPanel.options.legend.withDisplayMode('table') + timeSeriesPanel.options.legend.withPlacement('bottom')
        + timeSeriesPanel.options.legend.withCalcs(calcs) + timeSeriesPanel.options.legend.withSortBy('Mean') + timeSeriesPanel.options.legend.withSortDesc(true)
        + (if std.length(overrides) > 0 then timeSeriesPanel.standardOptions.withOverrides(overrides) else {})
        + timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc');

      local mysqlConnections =
        timeSeriesBase('MySQL Connections', '**Max Connections** \n\nMax Connections is the maximum permitted number of simultaneous client connections. By default, this is 151. Increasing this value increases the number of file descriptors that mysqld requires. If the required number of descriptors are not available, the server reduces the value of Max Connections.\n\nmysqld actually permits Max Connections + 1 clients to connect. The extra connection is reserved for use by accounts that have the SUPER privilege, such as root.\n\nMax Used Connections is the maximum number of connections that have been in use simultaneously since the server started.\n\nConnections is the number of connection attempts (successful or not) to the MySQL server.', overrides=[fill0Override('Max Connections')])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(max_over_time(mysql_global_status_threads_connected{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Connections'),
          promTarget('sum(mysql_global_status_max_used_connections{cluster="$cluster", job=~"$job", instance=~"$instance"})', 'Max Used Connections'),
          promTarget('sum(mysql_global_variables_max_connections{cluster="$cluster", job=~"$job", instance=~"$instance"})', 'Max Connections'),
        ]);

      local mysqlClientThreadActivity =
        timeSeriesBase('MySQL Client Thread Activity', '**MySQL Active Threads**\n\nThreads Connected is the number of open connections, while Threads Running is the number of threads not sleeping.', overrides=[
          colorOverride('Peak Threads Running', color.red),
          colorOverride('Peak Threads Connected', color.blue),
          colorOverride('Avg Threads Running', color.yellow),
        ])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(max_over_time(mysql_global_status_threads_connected{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Peak Threads Connected'),
          promTarget('sum(max_over_time(mysql_global_status_threads_running{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Peak Threads Running'),
          promTarget('sum(avg_over_time(mysql_global_status_threads_running{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Avg Threads Running'),
        ]);

      local mysqlQuestions =
        timeSeriesBase('MySQL Questions', '**MySQL Questions**\n\nThe number of statements executed by the server. This includes only statements sent to the server by clients and not statements executed within stored programs, unlike the Queries used in the QPS calculation. \n\nThis variable does not count the following commands:\n* ``COM_PING``\n* ``COM_STATISTICS``\n* ``COM_STMT_PREPARE``\n* ``COM_STMT_CLOSE``\n* ``COM_STMT_RESET``')
        + timeSeriesPanel.queryOptions.withTargets([promTarget('avg(rate(mysql_global_status_questions{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', '{{instance}}')]);

      local myssqlThreadCache =
        timeSeriesBase('MySQL Thread Cache', "**MySQL Thread Cache**\n\nThe thread_cache_size variable sets how many threads the server should cache to reuse. When a client disconnects, the client's threads are put in the cache if the cache is not full. It is autosized in MySQL 5.6.8 and above (capped to 100). Requests for threads are satisfied by reusing threads taken from the cache if possible, and only when the cache is empty is a new thread created.\n\n* *Threads_created*: The number of threads created to handle connections.\n* *Threads_cached*: The number of threads in the thread cache.", overrides=[fill0Override('Threads Created')])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(mysql_global_variables_thread_cache_size{cluster="$cluster", job=~"$job", instance=~"$instance"})', 'Thread Cache Size'),
          promTarget('sum(mysql_global_status_threads_cached{cluster="$cluster", job=~"$job", instance=~"$instance"})', 'Threads Cached'),
          promTarget('sum(rate(mysql_global_status_threads_created{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Threads Created'),
        ]);

      local mysqlTemporaryObjects =
        timeSeriesBase('MySQL Temporary Objects')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(rate(mysql_global_status_created_tmp_tables{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Created Tmp Tables'),
          promTarget('sum(rate(mysql_global_status_created_tmp_disk_tables{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Created Tmp Disk Tables'),
          promTarget('sum(rate(mysql_global_status_created_tmp_files{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Created Tmp Files'),
        ]);

      local mysqlSelectTypes =
        timeSeriesBase('MySQL Select Types', "**MySQL Select Types**\n\nAs with most relational databases, selecting based on indexes is more efficient than scanning an entire table's data. Here we see the counters for selects not done with indexes.\n\n* ***Select Scan*** is how many queries caused full table scans, in which all the data in the table had to be read and either discarded or returned.\n* ***Select Range*** is how many queries used a range scan, which means MySQL scanned all rows in a given range.\n* ***Select Full Join*** is the number of joins that are not joined on an index, this is usually a huge performance hit.")
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(rate(mysql_global_status_select_full_range_join{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Select Full Join'),
          promTarget('sum(rate(mysql_global_status_select_range{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Select Full Range Join'),
          promTarget('sum(rate(mysql_global_status_select_range_check{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Select Range'),
          promTarget('sum(rate(mysql_global_status_select_range_check{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Select Range Check'),
          promTarget('sum(rate(mysql_global_status_select_scan{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Select Scan'),
        ]);

      local mysqlSort =
        timeSeriesBase('MySQL Sorts', "**MySQL Sorts**\n\nDue to a query's structure, order, or other requirements, MySQL sorts the rows before returning them. For example, if a table is ordered 1 to 10 but you want the results reversed, MySQL then has to sort the rows to return 10 to 1.\n\nThis graph also shows when sorts had to scan a whole table or a given range of a table in order to return the results and which could not have been sorted via an index.")
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(rate(mysql_global_status_sort_rows{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Sort Rows'),
          promTarget('sum(rate(mysql_global_status_sort_range{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Sort Range'),
          promTarget('sum(rate(mysql_global_status_sort_merge_passes{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Sort Merge Passes'),
          promTarget('sum(rate(mysql_global_status_sort_scan{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Sort Scan'),
        ]);

      local mysqlSlowQueries =
        timeSeriesBase('MySQL Slow Queries', '**MySQL Slow Queries**\n\nSlow queries are defined as queries being slower than the long_query_time setting. For example, if you have long_query_time set to 3, all queries that take longer than 3 seconds to complete will show on this graph.')
        + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(rate(mysql_global_status_slow_queries{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Slow Queries')]);

      local mysqlAbortedConnections =
        timeSeriesBase('MySQL Aborted Connections', '**Aborted Connections**\n\nWhen a given host connects to MySQL and the connection is interrupted in the middle (for example due to bad credentials), MySQL keeps that info in a system table (since 5.6 this table is exposed in performance_schema).\n\nIf the amount of failed requests without a successful connection reaches the value of max_connect_errors, mysqld assumes that something is wrong and blocks the host from further connection.\n\nTo allow connections from that host again, you need to issue the ``FLUSH HOSTS`` statement.')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(rate(mysql_global_status_aborted_connects{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Aborted Connects (attempts)'),
          promTarget('sum(rate(mysql_global_status_aborted_clients{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Aborted Clients (timeout)'),
        ]);

      local mysqlTableLocks =
        timeSeriesBase('MySQL Table Locks', '**Table Locks**\n\nMySQL takes a number of different locks for varying reasons. In this graph we see how many Table level locks MySQL has requested from the storage engine. In the case of InnoDB, many times the locks could actually be row locks as it only takes table level locks in a few specific cases.\n\nIt is most useful to compare Locks Immediate and Locks Waited. If Locks waited is rising, it means you have lock contention. Otherwise, Locks Immediate rising and falling is normal activity.')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(rate(mysql_global_status_table_locks_immediate{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Table Locks Immediate'),
          promTarget('sum(rate(mysql_global_status_table_locks_waited{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Table Locks Waited'),
        ]);

      local mysqlNetworkTraffic =
        timeSeriesBase('MySQL Network Traffic', '**MySQL Network Traffic**\n\nHere we can see how much network traffic is generated by MySQL. Outbound is network traffic sent from MySQL and Inbound is network traffic MySQL has received.', 'Bps')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(rate(mysql_global_status_bytes_received{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Inbound'),
          promTarget('sum(rate(mysql_global_status_bytes_sent{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m]))', 'Outbound'),
        ]);

      local mysqlInternalMemoryOverview =
        timeSeriesBase('MySQL Internal Memory Overview', '***System Memory***: Total Memory for the system.\\\n***InnoDB Buffer Pool Data***: InnoDB maintains a storage area called the buffer pool for caching data and indexes in memory.\\\n***TokuDB Cache Size***: Similar in function to the InnoDB Buffer Pool,  TokuDB will allocate 50% of the installed RAM for its own cache.\\\n***Key Buffer Size***: Index blocks for MYISAM tables are buffered and are shared by all threads. key_buffer_size is the size of the buffer used for index blocks.\\\n***Adaptive Hash Index Size***: When InnoDB notices that some index values are being accessed very frequently, it builds a hash index for them in memory on top of B-Tree indexes.\\\n ***Query Cache Size***: The query cache stores the text of a SELECT statement together with the corresponding result that was sent to the client. The query cache has huge scalability problems in that only one thread can do an operation in the query cache at the same time.\\\n***InnoDB Dictionary Size***: The data dictionary is InnoDB ‘s internal catalog of tables. InnoDB stores the data dictionary on disk, and loads entries into memory while the server is running.\\\n***InnoDB Log Buffer Size***: The MySQL InnoDB log buffer allows transactions to run without having to write the log to disk before the transactions commit.', 'bytes')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(mysql_global_status_innodb_page_size{cluster="$cluster", job=~"$job", instance=~"$instance"} * on (instance) group_left() avg(mysql_global_status_buffer_pool_pages{cluster="$cluster", job=~"$job", instance=~"$instance", state="data"}) by (instance))', 'InnoDB Buffer Pool Data'),
          promTarget('sum(mysql_global_variables_innodb_log_buffer_size{cluster="$cluster", job=~"$job", instance=~"$instance"})', 'InnoDB Log Buffer Size'),
          promTarget('sum(mysql_global_variables_innodb_additional_mem_pool_size{cluster="$cluster", job=~"$job", instance=~"$instance"})', 'InnoDB Additional Memory Pool Size'),
          promTarget('sum(mysql_global_status_innodb_mem_dictionary{cluster="$cluster", job=~"$job", instance=~"$instance"})', 'InnoDB Dictionary Size'),
          promTarget('sum(mysql_global_variables_key_buffer_size{cluster="$cluster", job=~"$job", instance=~"$instance"})', 'Key Buffer Size'),
          promTarget('sum(mysql_global_variables_query_cache_size{cluster="$cluster", job=~"$job", instance=~"$instance"})', 'Query Cache Size'),
          promTarget('sum(mysql_global_status_innodb_mem_adaptive_hash{cluster="$cluster", job=~"$job", instance=~"$instance"})', 'Adaptive Hash Index Size'),
          promTarget('sum(mysql_global_variables_tokudb_cache_size{cluster="$cluster", job=~"$job", instance=~"$instance"})', 'TokuDB Cache Size'),
        ]);

      local topCommandCounters =
        timeSeriesBase('Top Command Counters', '**Top Command Counters**\n\nThe Com_{{xxx}} statement counter variables indicate the number of times each xxx statement has been executed. There is one status variable for each type of statement. For example, Com_delete and Com_update count [``DELETE``](https://dev.mysql.com/doc/refman/5.7/en/delete.html) and [``UPDATE``](https://dev.mysql.com/doc/refman/5.7/en/update.html) statements, respectively. Com_delete_multi and Com_update_multi are similar but apply to [``DELETE``](https://dev.mysql.com/doc/refman/5.7/en/delete.html) and [``UPDATE``](https://dev.mysql.com/doc/refman/5.7/en/update.html) statements that use multiple-table syntax.')
        + timeSeriesPanel.queryOptions.withTargets([promTarget('topk(5, rate(mysql_global_status_commands_total{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])>0)', 'Com_{{ command }}')]);

      local mysqlHandlers =
        timeSeriesBase('MySQL Handlers', "**MySQL Handlers**\n\nHandler statistics are internal statistics on how MySQL is selecting, updating, inserting, and modifying rows, tables, and indexes.\n\nThis is in fact the layer between the Storage Engine and MySQL.\n\n* `read_rnd_next` is incremented when the server performs a full table scan and this is a counter you don't really want to see with a high value.\n* `read_key` is incremented when a read is done with an index.\n* `read_next` is incremented when the storage engine is asked to 'read the next index entry'. A high value means a lot of index scans are being done.")
        + timeSeriesPanel.queryOptions.withTargets([promTarget('rate(mysql_global_status_handlers_total{instance=~"$host", handler!~"commit|rollback|savepoint.*|prepare"}[5m]) or irate(mysql_global_status_handlers_total{instance=~"$host", handler!~"commit|rollback|savepoint.*|prepare"}[5m])', '{{ handler }}')]);

      local mysqlTransactionHandlers =
        timeSeriesBase('MySQL Transaction Handlers')
        + timeSeriesPanel.queryOptions.withTargets([promTarget('rate(mysql_global_status_handlers_total{instance=~"$host", handler=~"commit|rollback|savepoint.*|prepare"}[5m]) or irate(mysql_global_status_handlers_total{instance=~"$host", handler=~"commit|rollback|savepoint.*|prepare"}[5m])', '{{ handler }}')]);

      local processStates =
        timeSeriesBase('Process States', calcs=['mean', 'max'])
        + timeSeriesPanel.queryOptions.withTargets([promTarget('mysql_info_schema_threads{cluster="$cluster", job=~"$job", instance=~"$instance"}', '{{ state }}')]);

      local topProcessStatesHourly =
        timeSeriesBase('Top Process States Hourly', fillOpacity=60, calcs=['mean', 'max'])
        + timeSeriesPanel.queryOptions.withTargets([promTarget('topk(5, avg_over_time(mysql_info_schema_threads{cluster="$cluster", job=~"$job", instance=~"$instance"}[1h]))', '{{ state }}')]);

      local mysqlQueryCacheMemory =
        timeSeriesBase('MySQL Query Cache Memory')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('avg(mysql_global_status_qcache_free_memory{cluster="$cluster", job=~"$job", instance=~"$instance"} by (instance)', 'Free Memory'),
          promTarget('avg(mysql_global_variables_query_cache_size{cluster="$cluster", job=~"$job", instance=~"$instance"} by (instance)', 'Query Cache Size'),
        ]);

      local mysqlQueryCacheActivity =
        timeSeriesBase('MySQL Query Cache Activity')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('avg(rate(mysql_global_status_qcache_hits{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_qcache_hits{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', 'Hits'),
          promTarget('avg(rate(mysql_global_status_qcache_inserts{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_qcache_inserts{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', 'Inserts'),
          promTarget('avg(rate(mysql_global_status_qcache_not_cached{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_qcache_not_cached{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', 'Not Cached'),
          promTarget('avg(rate(mysql_global_status_qcache_lowmem_prunes{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_qcache_lowmem_prunes{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', 'Prunes'),
          promTarget('avg(mysql_global_status_qcache_queries_in_cache{cluster="$cluster", job=~"$job", instance=~"$instance"}) by (instance)', 'Queries in Cache'),
        ]);

      local mysqlFileOpenings =
        timeSeriesBase('MySQL File Openings')
        + timeSeriesPanel.queryOptions.withTargets([promTarget('avg(rate(mysql_global_status_opened_files{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_opened_files{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', 'Openings')]);

      local mysqlOpenFiles =
        timeSeriesBase('MySQL Open Files')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('avg(mysql_global_status_open_files{cluster="$cluster", job=~"$job", instance=~"$instance"}) by (instance)', 'Open Files'),
          promTarget('avg(mysql_global_variables_open_files_limit{cluster="$cluster", job=~"$job", instance=~"$instance"}) by (instance)', 'Open Files Limit'),
          promTarget('avg(mysql_global_status_innodb_num_open_files{cluster="$cluster", job=~"$job", instance=~"$instance"}) by (instance)', 'InnoDB Open Files'),
        ]);

      local mysqlTableOpenCacheStatus =
        timeSeriesBase('MySQL Table Open Cache Status', '**MySQL Table Open Cache Status**\n\nThe recommendation is to set the `table_open_cache_instances` to a loose correlation to virtual CPUs, keeping in mind that more instances means the cache is split more times. If you have a cache set to 500 but it has 10 instances, each cache will only have 50 cached.\n\nThe `table_definition_cache` and `table_open_cache` can be left as default as they are auto-sized MySQL 5.6 and above (ie: do not set them to any value).', 'percentunit', overrides=[rightAxisOverride('Table Open Cache Hit Ratio')])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('avg(rate(mysql_global_status_opened_tables{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_opened_tables{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', 'Openings'),
          promTarget('avg(rate(mysql_global_status_table_open_cache_hits{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_table_open_cache_hits{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', 'Hits'),
          promTarget('avg(rate(mysql_global_status_table_open_cache_misses{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_table_open_cache_misses{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', 'Misses'),
          promTarget('avg(rate(mysql_global_status_table_open_cache_overflows{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_table_open_cache_overflows{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', 'Misses due to Overflows'),
          promTarget('(avg(rate(mysql_global_status_table_open_cache_hits{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_table_open_cache_hits{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance))/((avg(rate(mysql_global_status_table_open_cache_hits{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_table_open_cache_hits{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance))+(avg(rate(mysql_global_status_table_open_cache_misses{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_table_open_cache_misses{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)))', 'Table Open Cache Hit Ratio'),
        ]);

      local mysqlOpenTables =
        timeSeriesBase('MySQL Open Tables', '**MySQL Open Tables**\n\nThe recommendation is to set the `table_open_cache_instances` to a loose correlation to virtual CPUs, keeping in mind that more instances means the cache is split more times. If you have a cache set to 500 but it has 10 instances, each cache will only have 50 cached.\n\nThe `table_definition_cache` and `table_open_cache` can be left as default as they are auto-sized MySQL 5.6 and above (ie: do not set them to any value).')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('avg(mysql_global_status_open_tables{cluster="$cluster", job=~"$job", instance=~"$instance"}) by (instance)', 'Open Tables'),
          promTarget('avg(mysql_global_variables_table_open_cache{cluster="$cluster", job=~"$job", instance=~"$instance"}) by (instance)', 'Table Open Cache'),
        ]);

      local mysqlTableDefinitionCache =
        timeSeriesBase('MySQL Table Definition Cache', '**MySQL Table Definition Cache**\n\nThe recommendation is to set the `table_open_cache_instances` to a loose correlation to virtual CPUs, keeping in mind that more instances means the cache is split more times. If you have a cache set to 500 but it has 10 instances, each cache will only have 50 cached.\n\nThe `table_definition_cache` and `table_open_cache` can be left as default as they are auto-sized MySQL 5.6 and above (ie: do not set them to any value).', overrides=[rightAxisOverride('Opened Table Definitions')])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('avg(mysql_global_status_open_table_definitions{cluster="$cluster", job=~"$job", instance=~"$instance"}) by (instance)', 'Open Table Definitions'),
          promTarget('avg(mysql_global_variables_table_definition_cache{cluster="$cluster", job=~"$job", instance=~"$instance"}) by (instance)', 'Table Definitions Cache Size'),
          promTarget('avg(rate(mysql_global_status_opened_table_definitions{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_opened_table_definitions{cluster="$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', 'Opened Table Definitions'),
        ]);

      local panels = [
        row.new('Overview') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        upTimePanel { gridPos: { x: 0, y: 1, w: 8, h: 3 } },
        currentQPS { gridPos: { x: 8, y: 1, w: 8, h: 3 } },
        innoDBBufferPool { gridPos: { x: 16, y: 1, w: 8, h: 3 } },
        row.new('Connections') + { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
        mysqlConnections { gridPos: { x: 0, y: 5, w: 12, h: 7 } },
        mysqlClientThreadActivity { gridPos: { x: 12, y: 5, w: 12, h: 7 } },
        row.new('Table Locks') + { gridPos: { x: 0, y: 12, w: 24, h: 1 } },
        mysqlQuestions { gridPos: { x: 0, y: 13, w: 12, h: 7 } },
        myssqlThreadCache { gridPos: { x: 12, y: 13, w: 12, h: 7 } },
        row.new('Temporary Objects') + { gridPos: { x: 0, y: 20, w: 24, h: 1 } },
        mysqlTemporaryObjects { gridPos: { x: 0, y: 21, w: 12, h: 7 } },
        mysqlSelectTypes { gridPos: { x: 12, y: 21, w: 12, h: 7 } },
        row.new('Sorts') + { gridPos: { x: 0, y: 28, w: 24, h: 1 } },
        mysqlSort { gridPos: { x: 0, y: 29, w: 12, h: 7 } },
        mysqlSlowQueries { gridPos: { x: 12, y: 29, w: 12, h: 7 } },
        row.new('Aborted') + { gridPos: { x: 0, y: 36, w: 24, h: 1 } },
        mysqlAbortedConnections { gridPos: { x: 0, y: 37, w: 12, h: 7 } },
        mysqlTableLocks { gridPos: { x: 12, y: 37, w: 12, h: 7 } },
        row.new('Network') + { gridPos: { x: 0, y: 44, w: 24, h: 1 } },
        mysqlNetworkTraffic { gridPos: { x: 0, y: 45, w: 24, h: 7 } },
        row.new('Memory') + { gridPos: { x: 0, y: 52, w: 24, h: 1 } },
        mysqlInternalMemoryOverview { gridPos: { x: 0, y: 53, w: 24, h: 7 } },
        row.new('Command,Handlers,Processes') + { gridPos: { x: 0, y: 60, w: 24, h: 1 } },
        topCommandCounters { gridPos: { x: 0, y: 61, w: 24, h: 7 } },
        mysqlHandlers { gridPos: { x: 0, y: 68, w: 24, h: 7 } },
        mysqlTransactionHandlers { gridPos: { x: 0, y: 75, w: 24, h: 7 } },
        processStates { gridPos: { x: 0, y: 82, w: 24, h: 7 } },
        topProcessStatesHourly { gridPos: { x: 0, y: 89, w: 24, h: 7 } },
        row.new('Query cache') + { gridPos: { x: 0, y: 96, w: 24, h: 1 } },
        mysqlQueryCacheMemory { gridPos: { x: 0, y: 97, w: 12, h: 7 } },
        mysqlQueryCacheActivity { gridPos: { x: 12, y: 97, w: 12, h: 7 } },
        row.new('Files and Tables') + { gridPos: { x: 0, y: 104, w: 24, h: 1 } },
        mysqlFileOpenings { gridPos: { x: 0, y: 105, w: 12, h: 7 } },
        mysqlOpenFiles { gridPos: { x: 12, y: 105, w: 12, h: 7 } },
        row.new('Table openings') + { gridPos: { x: 0, y: 112, w: 24, h: 1 } },
        mysqlTableOpenCacheStatus { gridPos: { x: 0, y: 113, w: 12, h: 7 } },
        mysqlOpenTables { gridPos: { x: 12, y: 113, w: 12, h: 7 } },
        row.new('MySQL Table Definition Cache') + { gridPos: { x: 0, y: 120, w: 24, h: 1 } },
        mysqlTableDefinitionCache { gridPos: { x: 0, y: 121, w: 24, h: 7 } },
      ];

      dashboard.new('MySQL Exporter')
      + dashboard.withUid($._config.grafanaDashboards.ids.mysqlExporter)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sApps)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(mysql_up, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(mysql_up{cluster="$cluster"}, job)'),
        $.grafanaTemplates.instanceTemplate('label_values(mysql_up{cluster="$cluster", job=~"$job"}, instance)'),
      ])
      + dashboard.withPanels(panels),
  },
}
