local generateColumnOffsets(columnWidths) =
  std.foldl(function(columnOffsets, width) columnOffsets + [width + columnOffsets[std.length(columnOffsets) - 1]], columnWidths, [0]);

local generateRowOffsets(cellHeights) =
  std.foldl(function(rowOffsets, cellHeight) rowOffsets + [cellHeight + rowOffsets[std.length(rowOffsets) - 1]], cellHeights, [0]);

local generateDropOffsets(cellHeights, rowOffsets) =
  local totalHeight = std.foldl(function(sum, cellHeight) sum + cellHeight, cellHeights, 0);
  [
    totalHeight - rowOffset
    for rowOffset in rowOffsets
  ];


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

  // Layout all the panels in a single row
  singleRow(panels, rowHeight=10, startRow=0)::
    local cols = std.length(panels);
    self.grid(panels, cols=cols, rowHeight=rowHeight, startRow=startRow),

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

  // Each column contains an array of cells, stacked vertically
  // the heights of each cell are defined by cellHeights
  splitColumnGrid(columnsOfPanels, cellHeights, startRow)::
    local colWidth = std.floor(24 / std.length(columnsOfPanels));
    local rowOffsets = generateRowOffsets(cellHeights);
    local dropOffsets = generateDropOffsets(cellHeights, rowOffsets);

    std.prune(
      std.flattenArrays(
        std.mapWithIndex(
          function(colIndex, columnOfPanels)
            std.mapWithIndex(
              function(cellIndex, cell)
                if cell == null then
                  null
                else
                  local lastRowInColumn = cellIndex == (std.length(columnOfPanels) - 1);

                  // The height of the last cell will extend to the bottom
                  local height = if !lastRowInColumn then
                    cellHeights[cellIndex]
                  else
                    dropOffsets[cellIndex];

                  local gridPos = {
                    x: colWidth * colIndex,
                    y: rowOffsets[cellIndex] + startRow,
                    w: colWidth,
                    h: height,
                  };

                  cell {
                    gridPos: gridPos,
                  },
              columnOfPanels
            ),
          columnsOfPanels
        )
      )
    ),

}
