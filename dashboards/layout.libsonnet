local generateColumnOffsets(columnWidths) =
  std.foldl(function(columnOffsets, width) columnOffsets + [width + columnOffsets[std.length(columnOffsets) - 1]], columnWidths, [0]);

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

  columnGrid(rowsOfPanels, columnWidths, rowHeight=10, startRow=0)::
    local columnOffsets = generateColumnOffsets(columnWidths);

    std.flattenArrays(
      std.mapWithIndex(
        function(rowIndex, rowOfPanels)
          std.mapWithIndex(
            function(colIndex, panel)
              panel {
                gridPos: {
                  x: columnOffsets[colIndex],
                  y: rowIndex * rowHeight + startRow,
                  w: columnWidths[colIndex],
                  h: rowHeight,
                },
              },
            rowOfPanels
          ),
        rowsOfPanels
      )
    ),
}
