{
  upper:: {
    "alias": "upper normal",
    "dashes": true,
    "color": "#99440a",
    "fillBelowTo": "lower normal",
    "legend": false,
    "lines": false,
    "linewidth": 1,
    "zindex": -3,
    "dashLength": 8,
    "spaceLength": 8,
    "nullPointMode": "connected"
  },
  lower:: {
    "alias": "lower normal",
    "dashes": true,
    "color": "#99440a",
    "legend": false,
    "lines": false,
    "linewidth": 1,
    "zindex": -3,
    "dashLength": 8,
    "spaceLength": 8,
    "nullPointMode": "connected"
  },
  lastWeek:: {
    "alias": "last week",
    "dashes": true,
    "dashLength": 2,
    "spaceLength": 2,
    "fill": 0,
    "color": "#dddddd",
    "legend": true,
    "lines": true,
    "linewidth": 1,
    "zindex": -2,
    "nullPointMode": "connected"
  },
  alertFiring:: {
    "alias": "alert firing",
    "color": "orange",
    "zindex": -3,
  },
  alertPending:: {
    "alias": "alert pending",
    "color": "lightorange",
    "zindex": -3,
  },
  goldenMetric(alias):: self {
    "alias": alias,
    "color": "yellow",
  },
}
