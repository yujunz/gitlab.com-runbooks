local colors = import 'colors.libsonnet';

{
  upper:: {
    "alias": "upper normal",
    "dashes": true,
    "color": colors.normalRangeColor,
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
    "color": colors.normalRangeColor,
    "legend": false,
    "lines": false,
    "linewidth": 1,
    "zindex": -3,
    "dashLength": 8,
    "spaceLength": 8,
    "nullPointMode": "connected"
  },
  upperLegacy:: {
    "alias": "upper normal (legacy)",
    "dashes": true,
    "color": colors.normalRangeColor,
    "fillBelowTo": "lower normal (legacy)",
    "legend": false,
    "lines": false,
    "linewidth": 1,
    "zindex": -3,
    "dashLength": 8,
    "spaceLength": 8,
    "nullPointMode": "connected"
  },
  lowerLegacy:: {
    "alias": "lower normal (legacy)",
    "dashes": true,
    "color": colors.normalRangeColor,
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
    "color": "#dddddd40",
    "legend": true,
    "lines": true,
    "linewidth": 1,
    "zindex": -3,
    "nullPointMode": "connected"
  },
  alertFiring:: {
    "alias": "alert firing",
    "color": "orange",
    "zindex": -4,
  },
  alertPending:: {
    "alias": "alert pending",
    "color": "lightorange",
    "zindex": -4,
  },
  goldenMetric(alias):: self {
    "alias": alias,
    "color": "#E7D551", // "Brilliant gold"
  },
  slo:: {
    "alias": "SLO",
    "color": "#FF4500", // "Orange red"
    "dashes": true,
    "legend": true,
    "lines": true,
    "linewidth": 4,
    "dashLength": 4,
    "spaceLength": 4,
    "nullPointMode": "connected",
    "zindex": -2,
  },
  sloViolation:: {
    "alias": "/ SLO violation$/",
    "color": "#00000088",
    "dashes": true,
    "legend": false,
    "lines": true,
    "fill": true,
    "dashLength": 1,
    "spaceLength": 4,
  },
  mainStage:: {
    "alias": "main stage",
    "color": "#5794F2",
  },
  cnyStage:: {
    "alias": "cny stage",
    "color": "#FADE2A",
  },
  networkReceive:: {
    "alias": "/receive .*/",
    "transform": "negative-Y"
  },
}
