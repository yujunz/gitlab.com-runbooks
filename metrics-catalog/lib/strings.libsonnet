local removeBlankLines(str) = std.strReplace(str, '\n\n', '\n');

local chomp(str) =
  if std.isString(str) then
    std.rstripChars(str, '\n')
  else
    std.assertEqual(str, { __assert__: 'str should be a string value' });

local indent(str, spaces) =
  std.strReplace(removeBlankLines(chomp(str)), '\n', '\n' + std.repeat(' ', spaces));

{
  removeBlankLines(str):: removeBlankLines(str),
  chomp(str):: chomp(str),
  indent(str, spaces):: indent(str, spaces),
}
