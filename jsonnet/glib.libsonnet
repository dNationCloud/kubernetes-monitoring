local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local var = g.dashboard.variable;
local prometheus = g.query.prometheus;
local stat = g.panel.stat;
local table = g.panel.table;
{

    gVariables: {
        datasource()::
            var.datasource.new('datasource', 'prometheus')
            + var.datasource.generalOptions.showOnDashboard.withLabelAndValue()
            + var.datasource.generalOptions.withCurrent('thanos')
            + var.datasource.generalOptions.withLabel('Data source'),
        local datasource = $.gVariables.datasource,
        cluster(query)::
            var.query.new('cluster')
            + var.query.withDatasourceFromVariable(datasource())
            + var.query.queryTypes.withLabelValues('cluster',query)
            + var.query.generalOptions.withLabel('Cluster')
            + var.query.refresh.onTime()
            + var.query.withSort(type='alphabetical'),
        job(query)::
            var.query.new('job')
            + var.query.withDatasourceFromVariable(datasource())
            + var.query.generalOptions.withLabel('Job')
            + var.query.generalOptions.showOnDashboard.withLabelAndValue()
            + var.query.refresh.onTime()
            + var.query.selectionOptions.withIncludeAll(true)
            + var.query.withSort(type='alphabetical')
            + var.query.queryTypes.withLabelValues('job',query),
        instance(query):
            var.query.new('instance')
            + var.query.withDatasourceFromVariable(datasource())
            + var.query.refresh.onTime()
            + var.query.withSort(type='alphabetical')
            + var.query.generalOptions.showOnDashboard.withLabelAndValue()
            + var.query.selectionOptions.withIncludeAll(true)
            + var.query.queryTypes.withLabelValues('instance',query),
    },
    gStatPanels:{
        fixed(title,query,color="gray"):: stat.new (title)
        + stat.options.withGraphMode('none')
        + stat.standardOptions.color.withMode('fixed')
        + stat.standardOptions.color.withFixedColor('gray')
        + stat.queryOptions.withTargets([
            prometheus.new('$datasource',query)
            + prometheus.withInstant(true),
        ]),
        threshold(title,query,steps):: stat.new (title)
    + stat.options.withGraphMode('none')
    + stat.standardOptions.thresholds.withSteps(steps)
    + stat.standardOptions.thresholds.withMode("absolute")
    + stat.queryOptions.withTargets([
        prometheus.new('$datasource',query)
        + prometheus.withInstant(true),
    ]),
    },
    gTables:{
        threshold(
            title,
            query,
            steps,
            unit='none',
            decimals=0,
            hideRegexp= '',
            width=24
            ):: table.new(title)
        + table.standardOptions.thresholds.withMode("absoute")
        + table.standardOptions.thresholds.withSteps(steps)
        + table.fieldConfig.defaults.custom.cellOptions.TableColoredBackgroundCellOptions.withMode("basic")
        + table.fieldConfig.defaults.custom.cellOptions.TableColoredBackgroundCellOptions.withType()
        + table.gridPos.withW(width)
        + table.standardOptions.withOverrides([
            table.standardOptions.override.byName.new('Value')
            + table.standardOptions.override.byName.withPropertiesFromOptions(
                table.standardOptions.thresholds.withMode("absolute")
                + table.standardOptions.withUnit(unit)
                + table.standardOptions.withDecimals(decimals)
                + table.standardOptions.thresholds.withSteps(steps)
            ),
            table.standardOptions.override.byRegexp.new(hideRegexp)
            + table.standardOptions.override.byRegexp.withPropertiesFromOptions(table.fieldConfig.defaults.custom.withHidden())
        ],
        )
        + table.queryOptions.withTargets([
        prometheus.new('$datasource', query)
        + prometheus.withInstant(true)
        + prometheus.withFormat('table'),
        ]),
    local threshold = $.gTables.threshold,
    simple(
        title,
        query,
        unit='none',
        decimals=0,
        hideRegexp= '',
        width=24
    ):: threshold(title,query, $.gTableSteps.transparent,decimals,hideRegexp,width),
    local simple = $.gTables.simple,
    valueThreshold(
            title,
            query,
            steps,
            unit='none',
            decimals=0,
            hideRegexp= '',
            width=24
            ):: table.new(title)
        + table.standardOptions.thresholds.withMode("absoute")
        + table.standardOptions.thresholds.withSteps($.gTableSteps.transparent)
        + table.fieldConfig.defaults.custom.cellOptions.TableColoredBackgroundCellOptions.withMode("basic")
        + table.fieldConfig.defaults.custom.cellOptions.TableColoredBackgroundCellOptions.withType()
        + table.gridPos.withW(width)
        + table.standardOptions.withOverrides([
        table.standardOptions.override.byName.new('Value')
        + table.standardOptions.override.byName.withPropertiesFromOptions(
            table.standardOptions.thresholds.withMode("absolute")
            + table.standardOptions.withUnit(unit)
            + table.standardOptions.withDecimals(decimals)
            + table.standardOptions.thresholds.withSteps(steps)
        ),
        table.standardOptions.override.byRegexp.new('(Time|container|endpoint|job|namespace|prometheus.*|service|pod)')
        + table.standardOptions.override.byRegexp.withPropertiesFromOptions(table.fieldConfig.defaults.custom.withHidden())
        ],
        )
        + table.queryOptions.withTargets([
        prometheus.new('$datasource', query)
        + prometheus.withInstant(true)
        + prometheus.withFormat('table'),
    ])

    },
    gTableSteps:{
        transparent: [
            table.standardOptions.threshold.step.withValue(null)
            + table.standardOptions.threshold.step.withColor("transparent"),
        ],
        red: [
            table.standardOptions.threshold.step.withValue(null)
            + table.standardOptions.threshold.step.withColor("red"),
        ],
        //Red,Orange,Green for value Black for null
        standard(red,orange,green)::
        [
                table.standardOptions.threshold.step.withValue(red) + table.standardOptions.threshold.step.withColor("red"),
                table.standardOptions.threshold.step.withValue(orange) + table.standardOptions.threshold.step.withColor("orange"),
                table.standardOptions.threshold.step.withValue(green) + table.standardOptions.threshold.step.withColor("green"),
        ],
        alert(red,orange)::
        [
                table.standardOptions.threshold.step.withValue(orange) + table.standardOptions.threshold.step.withColor("orange"),
                table.standardOptions.threshold.step.withValue(green) + table.standardOptions.threshold.step.withColor("green"),
        ],
    }

}
