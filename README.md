# Использование
test.lua
```lua
require'bmp'

local forest = bmpDecode'forest.bmp'

print(forest)
```
____
Результат выполнения bmpDecode будет содержать такую структуру
```
{
  width = 587,
  height = 786,
  rows = {
    [1] = {
      [1] = {
        R = 255,
        G = 255,
        B = 255
      },
      ...
    },
    ...
  }
}
```
