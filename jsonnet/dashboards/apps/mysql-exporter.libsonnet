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

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local statPanel = grafana.statPanel;
local graphPanel = grafana.graphPanel;
local row = grafana.row;

{
  grafanaDashboards+:: {
    'mysql-exporter':
      local upTimePanel =
        statPanel.new(
          title='Uptime',
          description='**Uptime**\n\nThe amount of time since the last restart of the MySQL server process.',
          datasource='$datasource',
          graphMode='none',
          decimals=0,
          unit='s',
        )
        .addThresholds(
          [
            { color: $._config.grafanaDashboards.color.red, value: null },
            { color: $._config.grafanaDashboards.color.orange, value: 300 },
            { color: $._config.grafanaDashboards.color.green, value: 3600 },
          ]
        )
        .addTarget(prometheus.target('avg(mysql_global_status_uptime{cluster=~"$cluster", job=~"$job", instance=~"$instance"}) by (instance)', legendFormat='{{instance}}'));

      local currentQPS =
        statPanel.new(
          title='Current QPS',
          description="**Current QPS**\n\nBased on the queries reported by MySQL's ``SHOW STATUS`` command, it is the number of statements executed by the server within the last second. This variable includes statements executed within stored programs, unlike the Questions variable. It does not count \n``COM_PING`` or ``COM_STATISTICS`` commands.",
          datasource='$datasource',
          graphMode='none',
          decimals=0,
        )
        .addThresholds(
          [
            { color: $._config.grafanaDashboards.color.red, value: null },
            { color: $._config.grafanaDashboards.color.orange, value: 35 },
            { color: $._config.grafanaDashboards.color.green, value: 75 },
          ]
        )
        .addTarget(prometheus.target('avg(rate(mysql_global_status_queries{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', legendFormat='{{instance}}'));

      local innoDBBufferPool =
        statPanel.new(
          title='InnoDB Buffer Pool',
          description='**InnoDB Buffer Pool Size**\n\nInnoDB maintains a storage area called the buffer pool for caching data and indexes in memory.  Knowing how the InnoDB buffer pool works, and taking advantage of it to keep frequently accessed data in memory, is one of the most important aspects of MySQL tuning. The goal is to keep the working set in memory. In most cases, this should be between 60%-90% of available memory on a dedicated database host, but depends on many factors.',
          datasource='$datasource',
          graphMode='none',
          decimals=0,
          unit='bytes',
        )
        .addThresholds(
          [
            { color: $._config.grafanaDashboards.color.red, value: null },
            { color: $._config.grafanaDashboards.color.orange, value: 90 },
            { color: $._config.grafanaDashboards.color.green, value: 95 },
          ]
        )
        .addTarget(prometheus.target('avg(mysql_global_variables_innodb_buffer_pool_size{cluster=~"$cluster", job=~"$job", instance=~"$instance"}) by (instance)', legendFormat='{{instance}}'));

      local mysqlConnections =
        graphPanel.new(
          title='MySQL Connections',
          description='**Max Connections** \n\nMax Connections is the maximum permitted number of simultaneous client connections. By default, this is 151. Increasing this value increases the number of file descriptors that mysqld requires. If the required number of descriptors are not available, the server reduces the value of Max Connections.\n\nmysqld actually permits Max Connections + 1 clients to connect. The extra connection is reserved for use by accounts that have the SUPER privilege, such as root.\n\nMax Used Connections is the maximum number of connections that have been in use simultaneously since the server started.\n\nConnections is the number of connection attempts (successful or not) to the MySQL server.',
          datasource='$datasource',
          fill=2,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addSeriesOverride({ alias: 'Max Connections', fill: 0 })
        .addTargets(
          [
            prometheus.target('sum(max_over_time(mysql_global_status_threads_connected{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Connections'),
            prometheus.target('sum(mysql_global_status_max_used_connections{cluster=~"$cluster", job=~"$job", instance=~"$instance"})', legendFormat='Max Used Connections'),
            prometheus.target('sum(mysql_global_variables_max_connections{cluster=~"$cluster", job=~"$job", instance=~"$instance"})', legendFormat='Max Connections'),
          ]
        );

      local mysqlClientThreadActivity =
        graphPanel.new(
          title='MySQL Client Thread Activity',
          description='**MySQL Active Threads**\n\nThreads Connected is the number of open connections, while Threads Running is the number of threads not sleeping.',
          datasource='$datasource',
          fill=2,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addSeriesOverride({ alias: 'Peak Threads Running', color: $._config.grafanaDashboards.color.red })
        .addSeriesOverride({ alias: 'Peak Threads Connected', color: $._config.grafanaDashboards.color.blue })
        .addSeriesOverride({ alias: 'Avg Threads Running', color: $._config.grafanaDashboards.color.yellow })
        .addTargets(
          [
            prometheus.target('sum(max_over_time(mysql_global_status_threads_connected{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Peak Threads Connected'),
            prometheus.target('sum(max_over_time(mysql_global_status_threads_running{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Peak Threads Running'),
            prometheus.target('sum(avg_over_time(mysql_global_status_threads_running{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Avg Threads Running'),
          ]
        );

      local mysqlQuestions =
        graphPanel.new(
          title='MySQL Questions',
          description='**MySQL Questions**\n\nThe number of statements executed by the server. This includes only statements sent to the server by clients and not statements executed within stored programs, unlike the Queries used in the QPS calculation. \n\nThis variable does not count the following commands:\n* ``COM_PING``\n* ``COM_STATISTICS``\n* ``COM_STMT_PREPARE``\n* ``COM_STMT_CLOSE``\n* ``COM_STMT_RESET``',
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addTargets(
          [
            prometheus.target('avg(rate(mysql_global_status_questions{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', legendFormat='{{instance}}'),
          ]
        );

      local myssqlThreadCache =
        graphPanel.new(
          title='MySQL Thread Cache',
          description="**MySQL Thread Cache**\n\nThe thread_cache_size variable sets how many threads the server should cache to reuse. When a client disconnects, the client's threads are put in the cache if the cache is not full. It is autosized in MySQL 5.6.8 and above (capped to 100). Requests for threads are satisfied by reusing threads taken from the cache if possible, and only when the cache is empty is a new thread created.\n\n* *Threads_created*: The number of threads created to handle connections.\n* *Threads_cached*: The number of threads in the thread cache.",
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addSeriesOverride({ alias: 'Threads Created', fill: 0 })
        .addTargets(
          [
            prometheus.target('sum(mysql_global_variables_thread_cache_size{cluster=~"$cluster", job=~"$job", instance=~"$instance"})', legendFormat='Thread Cache Size'),
            prometheus.target('sum(mysql_global_status_threads_cached{cluster=~"$cluster", job=~"$job", instance=~"$instance"})', legendFormat='Threads Cached'),
            prometheus.target('sum(rate(mysql_global_status_threads_created{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Threads Created'),
          ]
        );

      local mysqlTemporaryObjects =
        graphPanel.new(
          title='MySQL Temporary Objects',
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addTargets(
          [
            prometheus.target('sum(rate(mysql_global_status_created_tmp_tables{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Created Tmp Tables'),
            prometheus.target('sum(rate(mysql_global_status_created_tmp_disk_tables{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Created Tmp Disk Tables'),
            prometheus.target('sum(rate(mysql_global_status_created_tmp_files{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Created Tmp Files'),
          ]
        );

      local mysqlSelectTypes =
        graphPanel.new(
          title='MySQL Select Types',
          description="**MySQL Select Types**\n\nAs with most relational databases, selecting based on indexes is more efficient than scanning an entire table's data. Here we see the counters for selects not done with indexes.\n\n* ***Select Scan*** is how many queries caused full table scans, in which all the data in the table had to be read and either discarded or returned.\n* ***Select Range*** is how many queries used a range scan, which means MySQL scanned all rows in a given range.\n* ***Select Full Join*** is the number of joins that are not joined on an index, this is usually a huge performance hit.",
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addTargets(
          [
            prometheus.target('sum(rate(mysql_global_status_select_full_range_join{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Select Full Join'),
            prometheus.target('sum(rate(mysql_global_status_select_range{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Select Full Range Join'),
            prometheus.target('sum(rate(mysql_global_status_select_range_check{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Select Range'),
            prometheus.target('sum(rate(mysql_global_status_select_range_check{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Select Range Check'),
            prometheus.target('sum(rate(mysql_global_status_select_scan{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Select Scan'),
          ]
        );

      local mysqlSort =
        graphPanel.new(
          title='MySQL Sorts',
          description="**MySQL Sorts**\n\nDue to a query's structure, order, or other requirements, MySQL sorts the rows before returning them. For example, if a table is ordered 1 to 10 but you want the results reversed, MySQL then has to sort the rows to return 10 to 1.\n\nThis graph also shows when sorts had to scan a whole table or a given range of a table in order to return the results and which could not have been sorted via an index.",
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addTargets(
          [
            prometheus.target('sum(rate(mysql_global_status_sort_rows{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Sort Rows'),
            prometheus.target('sum(rate(mysql_global_status_sort_range{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Sort Range'),
            prometheus.target('sum(rate(mysql_global_status_sort_merge_passes{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Sort Merge Passes'),
            prometheus.target('sum(rate(mysql_global_status_sort_scan{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Sort Scan'),
          ]
        );

      local mysqlSlowQueries =
        graphPanel.new(
          title='MySQL Slow Queries',
          description='**MySQL Slow Queries**\n\nSlow queries are defined as queries being slower than the long_query_time setting. For example, if you have long_query_time set to 3, all queries that take longer than 3 seconds to complete will show on this graph.',
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addTargets(
          [
            prometheus.target('sum(rate(mysql_global_status_slow_queries{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Slow Queries'),
          ]
        );

      local mysqlAbortedConnections =
        graphPanel.new(
          title='MySQL Aborted Connections',
          description='**Aborted Connections**\n\nWhen a given host connects to MySQL and the connection is interrupted in the middle (for example due to bad credentials), MySQL keeps that info in a system table (since 5.6 this table is exposed in performance_schema).\n\nIf the amount of failed requests without a successful connection reaches the value of max_connect_errors, mysqld assumes that something is wrong and blocks the host from further connection.\n\nTo allow connections from that host again, you need to issue the ``FLUSH HOSTS`` statement.',
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addTargets(
          [
            prometheus.target('sum(rate(mysql_global_status_aborted_connects{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Aborted Connects (attempts)'),
            prometheus.target('sum(rate(mysql_global_status_aborted_clients{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Aborted Clients (timeout)'),
          ]
        );

      local mysqlTableLocks =
        graphPanel.new(
          title='MySQL Table Locks',
          description='**Table Locks**\n\nMySQL takes a number of different locks for varying reasons. In this graph we see how many Table level locks MySQL has requested from the storage engine. In the case of InnoDB, many times the locks could actually be row locks as it only takes table level locks in a few specific cases.\n\nIt is most useful to compare Locks Immediate and Locks Waited. If Locks waited is rising, it means you have lock contention. Otherwise, Locks Immediate rising and falling is normal activity.',
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addTargets(
          [
            prometheus.target('sum(rate(mysql_global_status_table_locks_immediate{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Table Locks Immediate'),
            prometheus.target('sum(rate(mysql_global_status_table_locks_waited{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Table Locks Waited'),
          ]
        );

      local mysqlNetworkTraffic =
        graphPanel.new(
          title='MySQL Network Traffic',
          description='**MySQL Network Traffic**\n\nHere we can see how much network traffic is generated by MySQL. Outbound is network traffic sent from MySQL and Inbound is network traffic MySQL has received.',
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
          format='Bps',
        )
        .addTargets(
          [
            prometheus.target('sum(rate(mysql_global_status_bytes_received{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Inbound'),
            prometheus.target('sum(rate(mysql_global_status_bytes_sent{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m]))', legendFormat='Outbound'),
          ]
        );

      local mysqlInternalMemoryOverview =
        graphPanel.new(
          title='MySQL Internal Memory Overview',
          description='***System Memory***: Total Memory for the system.\\\n***InnoDB Buffer Pool Data***: InnoDB maintains a storage area called the buffer pool for caching data and indexes in memory.\\\n***TokuDB Cache Size***: Similar in function to the InnoDB Buffer Pool,  TokuDB will allocate 50% of the installed RAM for its own cache.\\\n***Key Buffer Size***: Index blocks for MYISAM tables are buffered and are shared by all threads. key_buffer_size is the size of the buffer used for index blocks.\\\n***Adaptive Hash Index Size***: When InnoDB notices that some index values are being accessed very frequently, it builds a hash index for them in memory on top of B-Tree indexes.\\\n ***Query Cache Size***: The query cache stores the text of a SELECT statement together with the corresponding result that was sent to the client. The query cache has huge scalability problems in that only one thread can do an operation in the query cache at the same time.\\\n***InnoDB Dictionary Size***: The data dictionary is InnoDB ‘s internal catalog of tables. InnoDB stores the data dictionary on disk, and loads entries into memory while the server is running.\\\n***InnoDB Log Buffer Size***: The MySQL InnoDB log buffer allows transactions to run without having to write the log to disk before the transactions commit.',
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
          format='bytes',
        )
        .addTargets(
          [
            prometheus.target('sum(mysql_global_status_innodb_page_size{cluster=~"$cluster", job=~"$job", instance=~"$instance"} * on (instance) group_left() avg(mysql_global_status_buffer_pool_pages{cluster=~"$cluster", job=~"$job", instance=~"$instance", state="data"}) by (instance))', legendFormat='InnoDB Buffer Pool Data'),
            prometheus.target('sum(mysql_global_variables_innodb_log_buffer_size{cluster=~"$cluster", job=~"$job", instance=~"$instance"})', legendFormat='InnoDB Log Buffer Size'),
            prometheus.target('sum(mysql_global_variables_innodb_additional_mem_pool_size{cluster=~"$cluster", job=~"$job", instance=~"$instance"})', legendFormat='InnoDB Additional Memory Pool Size'),
            prometheus.target('sum(mysql_global_status_innodb_mem_dictionary{cluster=~"$cluster", job=~"$job", instance=~"$instance"})', legendFormat='InnoDB Dictionary Size'),
            prometheus.target('sum(mysql_global_variables_key_buffer_size{cluster=~"$cluster", job=~"$job", instance=~"$instance"})', legendFormat='Key Buffer Size'),
            prometheus.target('sum(mysql_global_variables_query_cache_size{cluster=~"$cluster", job=~"$job", instance=~"$instance"})', legendFormat='Query Cache Size'),
            prometheus.target('sum(mysql_global_status_innodb_mem_adaptive_hash{cluster=~"$cluster", job=~"$job", instance=~"$instance"})', legendFormat='Adaptive Hash Index Size'),
            prometheus.target('sum(mysql_global_variables_tokudb_cache_size{cluster=~"$cluster", job=~"$job", instance=~"$instance"})', legendFormat='TokuDB Cache Size'),
          ]
        );

      local topCommandCounters =
        graphPanel.new(
          title='Top Command Counters',
          description='**Top Command Counters**\n\nThe Com_{{xxx}} statement counter variables indicate the number of times each xxx statement has been executed. There is one status variable for each type of statement. For example, Com_delete and Com_update count [``DELETE``](https://dev.mysql.com/doc/refman/5.7/en/delete.html) and [``UPDATE``](https://dev.mysql.com/doc/refman/5.7/en/update.html) statements, respectively. Com_delete_multi and Com_update_multi are similar but apply to [``DELETE``](https://dev.mysql.com/doc/refman/5.7/en/delete.html) and [``UPDATE``](https://dev.mysql.com/doc/refman/5.7/en/update.html) statements that use multiple-table syntax.',
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addTargets(
          [
            prometheus.target('topk(5, rate(mysql_global_status_commands_total{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])>0)', legendFormat='Com_{{ command }}'),
          ]
        );

      local mysqlHandlers =
        graphPanel.new(
          title='MySQL Handlers',
          description="**MySQL Handlers**\n\nHandler statistics are internal statistics on how MySQL is selecting, updating, inserting, and modifying rows, tables, and indexes.\n\nThis is in fact the layer between the Storage Engine and MySQL.\n\n* `read_rnd_next` is incremented when the server performs a full table scan and this is a counter you don't really want to see with a high value.\n* `read_key` is incremented when a read is done with an index.\n* `read_next` is incremented when the storage engine is asked to 'read the next index entry'. A high value means a lot of index scans are being done.",
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addTargets(
          [
            prometheus.target('rate(mysql_global_status_handlers_total{instance=~"$host", handler!~"commit|rollback|savepoint.*|prepare"}[5m]) or irate(mysql_global_status_handlers_total{instance=~"$host", handler!~"commit|rollback|savepoint.*|prepare"}[5m])', legendFormat='{{ handler }}'),
          ]
        );

      local mysqlTransactionHandlers =
        graphPanel.new(
          title='MySQL Transaction Handlers',
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addTargets(
          [
            prometheus.target('rate(mysql_global_status_handlers_total{instance=~"$host", handler=~"commit|rollback|savepoint.*|prepare"}[5m]) or irate(mysql_global_status_handlers_total{instance=~"$host", handler=~"commit|rollback|savepoint.*|prepare"}[5m])', legendFormat='{{ handler }}'),
          ]
        );

      local processStates =
        graphPanel.new(
          title='Process States',
          datasource='$datasource',
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
        )
        .addTargets(
          [
            prometheus.target('mysql_info_schema_threads{cluster=~"$cluster", job=~"$job", instance=~"$instance"}', legendFormat='{{ state }}'),
          ]
        );

      local topProcessStatesHourly =
        graphPanel.new(
          title='Top Process States Hourly',
          datasource='$datasource',
          fill=6,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
        )
        .addTargets(
          [
            prometheus.target('topk(5, avg_over_time(mysql_info_schema_threads{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[1h]))', legendFormat='{{ state }}'),
          ]
        );

      local mysqlQueryCacheMemory =
        graphPanel.new(
          title='MySQL Query Cache Memory',
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addTargets(
          [
            prometheus.target('avg(mysql_global_status_qcache_free_memory{cluster=~"$cluster", job=~"$job", instance=~"$instance"} by (instance)', legendFormat='Free Memory'),
            prometheus.target('avg(mysql_global_variables_query_cache_size{cluster=~"$cluster", job=~"$job", instance=~"$instance"} by (instance)', legendFormat='Query Cache Size'),
          ]
        );

      local mysqlQueryCacheActivity =
        graphPanel.new(
          title='MySQL Query Cache Activity',
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addTargets(
          [
            prometheus.target('avg(rate(mysql_global_status_qcache_hits{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_qcache_hits{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', legendFormat='Hits'),
            prometheus.target('avg(rate(mysql_global_status_qcache_inserts{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_qcache_inserts{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', legendFormat='Inserts'),
            prometheus.target('avg(rate(mysql_global_status_qcache_not_cached{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_qcache_not_cached{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', legendFormat='Not Cached'),
            prometheus.target('avg(rate(mysql_global_status_qcache_lowmem_prunes{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_qcache_lowmem_prunes{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', legendFormat='Prunes'),
            prometheus.target('avg(mysql_global_status_qcache_queries_in_cache{cluster=~"$cluster", job=~"$job", instance=~"$instance"}) by (instance)', legendFormat='Queries in Cache'),
          ]
        );

      local mysqlFileOpenings =
        graphPanel.new(
          title='MySQL File Openings',
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addTargets(
          [
            prometheus.target('avg(rate(mysql_global_status_opened_files{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_opened_files{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', legendFormat='Openings'),
          ]
        );

      local mysqlOpenFiles =
        graphPanel.new(
          title='MySQL Open Files',
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addTargets(
          [
            prometheus.target('avg(mysql_global_status_open_files{cluster=~"$cluster", job=~"$job", instance=~"$instance"}) by (instance)', legendFormat='Open Files'),
            prometheus.target('avg(mysql_global_variables_open_files_limit{cluster=~"$cluster", job=~"$job", instance=~"$instance"}) by (instance)', legendFormat='Open Files Limit'),
            prometheus.target('avg(mysql_global_status_innodb_num_open_files{cluster=~"$cluster", job=~"$job", instance=~"$instance"}) by (instance)', legendFormat='InnoDB Open Files'),
          ]
        );

      local mysqlTableOpenCacheStatus =
        graphPanel.new(
          title='MySQL Table Open Cache Status',
          description='**MySQL Table Open Cache Status**\n\nThe recommendation is to set the `table_open_cache_instances` to a loose correlation to virtual CPUs, keeping in mind that more instances means the cache is split more times. If you have a cache set to 500 but it has 10 instances, each cache will only have 50 cached.\n\nThe `table_definition_cache` and `table_open_cache` can be left as default as they are auto-sized MySQL 5.6 and above (ie: do not set them to any value).',
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
          format='percentunit'
        )
        .addSeriesOverride({ alias: 'Table Open Cache Hit Ratio', yaxis: 2 })
        .addTargets(
          [
            prometheus.target('avg(rate(mysql_global_status_opened_tables{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_opened_tables{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', legendFormat='Openings'),
            prometheus.target('avg(rate(mysql_global_status_table_open_cache_hits{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_table_open_cache_hits{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', legendFormat='Hits'),
            prometheus.target('avg(rate(mysql_global_status_table_open_cache_misses{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_table_open_cache_misses{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', legendFormat='Misses'),
            prometheus.target('avg(rate(mysql_global_status_table_open_cache_overflows{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_table_open_cache_overflows{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', legendFormat='Misses due to Overflows'),
            prometheus.target('(avg(rate(mysql_global_status_table_open_cache_hits{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_table_open_cache_hits{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance))/((avg(rate(mysql_global_status_table_open_cache_hits{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_table_open_cache_hits{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance))+(avg(rate(mysql_global_status_table_open_cache_misses{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_table_open_cache_misses{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)))', legendFormat='Table Open Cache Hit Ratio'),
          ]
        );

      local mysqlOpenTables =
        graphPanel.new(
          title='MySQL Open Tables',
          description='**MySQL Open Tables**\n\nThe recommendation is to set the `table_open_cache_instances` to a loose correlation to virtual CPUs, keeping in mind that more instances means the cache is split more times. If you have a cache set to 500 but it has 10 instances, each cache will only have 50 cached.\n\nThe `table_definition_cache` and `table_open_cache` can be left as default as they are auto-sized MySQL 5.6 and above (ie: do not set them to any value).',
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addTargets(
          [
            prometheus.target('avg(mysql_global_status_open_tables{cluster=~"$cluster", job=~"$job", instance=~"$instance"}) by (instance)', legendFormat='Open Tables'),
            prometheus.target('avg(mysql_global_variables_table_open_cache{cluster=~"$cluster", job=~"$job", instance=~"$instance"}) by (instance)', legendFormat='Table Open Cache'),
          ]
        );

      local mysqlTableDefinitionCache =
        graphPanel.new(
          title='MySQL Table Definition Cache',
          description='**MySQL Table Definition Cache**\n\nThe recommendation is to set the `table_open_cache_instances` to a loose correlation to virtual CPUs, keeping in mind that more instances means the cache is split more times. If you have a cache set to 500 but it has 10 instances, each cache will only have 50 cached.\n\nThe `table_definition_cache` and `table_open_cache` can be left as default as they are auto-sized MySQL 5.6 and above (ie: do not set them to any value).',
          datasource='$datasource',
          fill=2,
          legend_show=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_values=true,
          legend_max=true,
          legend_min=true,
        )
        .addSeriesOverride({ alias: 'Opened Table Definitions', yaxis: 2 })
        .addTargets(
          [
            prometheus.target('avg(mysql_global_status_open_table_definitions{cluster=~"$cluster", job=~"$job", instance=~"$instance"}) by (instance)', legendFormat='Open Table Definitions'),
            prometheus.target('avg(mysql_global_variables_table_definition_cache{cluster=~"$cluster", job=~"$job", instance=~"$instance"}) by (instance)', legendFormat='Table Definitions Cache Size'),
            prometheus.target('avg(rate(mysql_global_status_opened_table_definitions{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance) or avg(irate(mysql_global_status_opened_table_definitions{cluster=~"$cluster", job=~"$job", instance=~"$instance"}[5m])) by (instance)', legendFormat='Opened Table Definitions'),
          ]
        );

      local templates =
        [
          $.grafanaTemplates.datasourceTemplate(),
          $.grafanaTemplates.clusterTemplate('label_values(mysql_up, cluster)'),
          $.grafanaTemplates.jobTemplate('label_values(mysql_up{cluster=~"$cluster"}, job)'),
          $.grafanaTemplates.instanceTemplate('label_values(mysql_up{cluster=~"$cluster", job=~"$job"}, instance)'),
        ];

      dashboard.new(
        'MySQL Exporter',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sApps,
        uid=$._config.grafanaDashboards.ids.mysqlExporter,
      )
      .addTemplates(templates)
      .addPanels(
        [
          row.new('Overview') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          upTimePanel { gridPos: { x: 0, y: 1, w: 8, h: 3 } },
          currentQPS { gridPos: { x: 8, y: 1, w: 8, h: 3 } },
          innoDBBufferPool { gridPos: { x: 16, y: 1, w: 8, h: 3 } },
          row.new('Connections') { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
          mysqlConnections { gridPos: { x: 0, y: 5, w: 12, h: 7 } },
          mysqlClientThreadActivity { gridPos: { x: 12, y: 5, w: 12, h: 7 } },
          row.new('Table Locks') { gridPos: { x: 0, y: 13, w: 24, h: 1 } },
          mysqlQuestions { gridPos: { x: 0, y: 14, w: 12, h: 7 } },
          myssqlThreadCache { gridPos: { x: 12, y: 14, w: 12, h: 7 } },
          row.new('Temporary Objects', collapse=true) { gridPos: { x: 0, y: 21, w: 24, h: 1 } }
          .addPanel(mysqlTemporaryObjects { tooltip+: { sort: 2 } }, { x: 0, y: 22, w: 12, h: 7 })
          .addPanel(mysqlSelectTypes { tooltip+: { sort: 2 } }, { x: 12, y: 22, w: 12, h: 7 }),
          row.new('Sorts', collapse=true) { gridPos: { x: 0, y: 22, w: 24, h: 1 } }
          .addPanel(mysqlSort { tooltip+: { sort: 2 } }, { x: 0, y: 23, w: 12, h: 7 })
          .addPanel(mysqlSlowQueries { tooltip+: { sort: 2 } }, { x: 12, y: 23, w: 12, h: 7 }),
          row.new('Aborted', collapse=true) { gridPos: { x: 0, y: 23, w: 24, h: 1 } }
          .addPanel(mysqlAbortedConnections { tooltip+: { sort: 2 } }, { x: 0, y: 24, w: 12, h: 7 })
          .addPanel(mysqlTableLocks { tooltip+: { sort: 2 } }, { x: 12, y: 24, w: 12, h: 7 }),
          row.new('Network', collapse=true) { gridPos: { x: 0, y: 24, w: 24, h: 1 } }
          .addPanel(mysqlNetworkTraffic { tooltip+: { sort: 2 } }, { x: 0, y: 25, w: 24, h: 7 }),
          row.new('Memory', collapse=true) { gridPos: { x: 0, y: 25, w: 24, h: 1 } }
          .addPanel(mysqlInternalMemoryOverview { tooltip+: { sort: 2 } }, { x: 0, y: 26, w: 24, h: 7 }),
          row.new('Command,Handlers,Processes', collapse=true) { gridPos: { x: 0, y: 26, w: 24, h: 1 } }
          .addPanel(topCommandCounters { tooltip+: { sort: 2 } }, { x: 0, y: 27, w: 24, h: 7 })
          .addPanel(mysqlHandlers { tooltip+: { sort: 2 } }, { x: 0, y: 34, w: 24, h: 7 })
          .addPanel(mysqlTransactionHandlers { tooltip+: { sort: 2 } }, { x: 0, y: 41, w: 24, h: 7 })
          .addPanel(processStates { tooltip+: { sort: 2 } }, { x: 0, y: 48, w: 24, h: 7 })
          .addPanel(topProcessStatesHourly { tooltip+: { sort: 2 } }, { x: 0, y: 55, w: 24, h: 7 }),
          row.new('Query cache', collapse=true) { gridPos: { x: 0, y: 27, w: 24, h: 1 } }
          .addPanel(mysqlQueryCacheMemory { tooltip+: { sort: 2 } }, { x: 0, y: 28, w: 12, h: 7 })
          .addPanel(mysqlQueryCacheActivity { tooltip+: { sort: 2 } }, { x: 12, y: 28, w: 12, h: 7 }),
          row.new('Files and Tables', collapse=true) { gridPos: { x: 0, y: 28, w: 24, h: 1 } }
          .addPanel(mysqlFileOpenings { tooltip+: { sort: 2 } }, { x: 0, y: 29, w: 12, h: 7 })
          .addPanel(mysqlOpenFiles { tooltip+: { sort: 2 } }, { x: 12, y: 29, w: 12, h: 7 }),
          row.new('Table openings', collapse=true) { gridPos: { x: 0, y: 29, w: 24, h: 1 } }
          .addPanel(mysqlTableOpenCacheStatus { tooltip+: { sort: 2 } }, { x: 0, y: 30, w: 12, h: 7 })
          .addPanel(mysqlOpenTables { tooltip+: { sort: 2 } }, { x: 12, y: 30, w: 12, h: 7 }),
          row.new('MySQL Table Definition Cache', collapse=true) { gridPos: { x: 0, y: 30, w: 24, h: 1 } }
          .addPanel(mysqlTableDefinitionCache { tooltip+: { sort: 2 } }, { x: 0, y: 31, w: 24, h: 7 }),
        ]
      ),
  },
}
