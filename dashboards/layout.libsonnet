{
  grid(panels, cols=2, rowHeight=10, startRow=0)::
    std.mapWithIndex(
      function(index, panel)
        panel {
          gridPos: {
            x: ((24 / cols) * index) % 24,
            y: std.floor(((24 / cols) * index) / 24) * rowHeight + startRow,
            w: 24 / cols,
            h: rowHeight,
          },
        },
      panels
    ),
}
