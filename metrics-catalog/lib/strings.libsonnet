local removeBlankLines(str) = std.strReplace(str, '\n\n', '\n');

local chomp(str) = std.rstripChars(str, '\n');

local indent(str, spaces) =
  std.strReplace(removeBlankLines(chomp(str)), '\n', '\n' + std.repeat(' ', spaces));

{
  removeBlankLines(str):: removeBlankLines(str),
  chomp(str):: chomp(str),
  indent(str, spaces):: indent(str, spaces),
}
