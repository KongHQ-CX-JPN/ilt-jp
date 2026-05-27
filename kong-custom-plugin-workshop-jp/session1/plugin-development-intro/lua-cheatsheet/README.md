## コメント

```lua
-- コメント
--[[ 複数行の
     コメント ]]
```

## 関数呼び出し

```lua
print()
print("Hi")

-- 引数が文字列またはテーブル形式の場合は括弧を省略できます。
print "Hello World"     <-->     print("Hello World")
dofile 'a.lua'          <-->     dofile ('a.lua')
print [[a multi-line    <-->     print([[a multi-line
 message]]                        message]])
f{x=10, y=20}           <-->     f({x=10, y=20})
type{}                  <-->     type({})
```

## テーブル / 列

```lua
t = {}
t = { a = 1, b = 2 }
t.a = function() ... end

t = { ["hello"] = 200 }
t.hello

-- 列はテーブルでもある
array = { "a", "b", "c", "d" }
print(array[2])       -- "b" (one-indexed)
print(#array)         -- 4 (length)
```

## 繰り返し

```lua
while condition do
end

for i = 1,5 do
end

for i = start,finish,delta do
end

for k,v in pairs(tab) do
end

repeat
until condition

-- Break文
while x do
  if condition then break end
end
```

## 条件式

```lua
if condition then
  print("yes")
elseif condition then
  print("maybe")
else
  print("no")
end
Variables
local x = 2
two, four = 2, 4
Functions
function myFunction()
  return 1
end

function myFunctionWithArgs(a, b)
  -- ...
end

myFunction()

anonymousFunctions(function()
  -- ...
end)

-- モジュールにExportされない
local function myPrivateFunction()
end

-- Splats（可変引数）
function doAction(action, ...)
  print("Doing '"..action.."' to", ...)
  --> print("Doing 'write' to", "Shirley", "Abed")
end

doAction('write', "Shirley", "Abed")
Lookups
mytable = { x = 2, y = function() .. end }

-- 以下は同じ意味:
mytable.x
mytable['x']

-- 糖衣構文。以下は同じ意味:
mytable.y(mytable)
mytable:y()

mytable.y(mytable, a, b)
mytable:y(a, b)

function X:y(z) .. end
function X.y(self, z) .. end
Metatables
mt = {}

-- メタテーブルは、単に関数を含むテーブルです。
mt.__tostring = function() return "lol" end
mt.__add      = function(b) ... end       -- a + b
mt.__mul      = function(b) ... end       -- a * b
mt.__index    = function(k) ... end       -- Lookups (a[k] or a.k)
mt.__newindex = function(k, v) ... end    -- Setters (a[k] = v)

-- メタテーブルを使用すると、別のテーブルの動作をオーバーライドできます。
mytable = {}
setmetatable(mytable, mt)

print(myobject)
```

## クラス

```lua
Account = {}

function Account:new(balance)
  local t = setmetatable({}, { __index = Account })

  -- コンストラクタ
  t.balance = (balance or 0)
  return t
end

function Account:withdraw(amount)
  print("Withdrawing "..amount.."...")
  self.balance = self.balance - amount
  self:report()
end

function Account:report()
  print("Your current balance is: "..self.balance)
end

a = Account:new(9000)
a:withdraw(200)    -- メソッド呼び出し
```

## 定数

```lua
nil
false
true
```

## 演算子 (とメタテーブルの名前)

```lua
-- 関係演算子 (binary)
-- __eq  __lt  __gt  __le  __ge
   ==    <     >     <=    >=
~=   -- Not equal, != のようなもの

-- 算術演算子 (binary)
-- __add  __sub  __muv  __div  __mod  __pow
   +      -      *      /      %      ^

-- 算術演算子 (単項)
-- __unm (単項でのマイナス)
   -

-- 論理演算子 (and/or)
nil and false  --> nil
false and nil  --> false
0 and 20       --> 20
10 and 20      --> 20


-- 長さ
-- __len(array)
#array


-- インデックス
-- __index(table, key)
t[key]
t.key

-- __newindex(table, key, value)
t[key]=value

-- 文字列の連結
-- __concat(left, right)
"hello, "..name

-- 呼び出し
-- __call(func, ...)
```

## API: グローバル関数

```lua
dofile("hello.lua")  -- Luaファイルを読み込み実行
loadfile("hello.lua") -- Luaファイルを読み込むだけ

assert(x)    -- x かどうか (errorをあげる)
assert(x, "failed")

type(var)   -- "nil" | "number" | "string" | "boolean" | "table" | "function" | "thread" | "userdata"

-- メタメソッドを呼び出さない (__indexと__newindexを使わない)
rawset(t, index, value)    -- t[index] = value をメタテーブルを使わず実装
rawget(t, index)           -- t[index] をメタテーブルを使わず実装

_G  -- グローバルコンテキスト
setfenv(1, {})  -- _Gを切り替える（Lua5.2以降では利用できない）

pairs(t)     -- {key, value}の反復可能リスト
ipairs(t)    -- {index, value}の反復可能リスト

tonumber("34")  -- 文字列を数値に変換
tonumber("8f", 16)
```
## API: 文字列

```lua
'文字列'..'連結'

s = "Hello"
s:upper()   -- 文字列を大文字に変換
s:lower()   -- 文字列を小文字に変換
s:len()     -- 文字列長の取得　※Luaだと#sでも文字列長が取得できる

s:find("l")    -- 文字列内で部分文字列を検索し、最初に見つかった開始位置と終了位置を返答
s:gfind("%w+")   -- 文字列検索の反復子を生成　※5.2以降で非推奨でありgmatchへの移行が推奨

s:match("l+")   -- パターンに一致する最初の部分文字列を返答
s:gmatch(".")  -- パターンに一致する部分文字列を順に返す反復子を生成

s:sub(2, 4)     -- 文字列の指定した範囲を抽出
s:gsub("l", "1")    -- 指定したパターンに一致する部分を置換し、新しい文字列と置換回数を返答

s:rep(3)     -- 文字列を指定回数繰り返した新しい文字列を返答
string.char(65)    -- 数値を文字コードとして扱い、対応する文字列を生成
string.dump(function)    -- 関数をバイナリ文字列としてシリアライズ
s:reverse() -- 文字列を反転した新しい文字列を返答
s:byte(2)    -- 文字列内の指定位置の文字の文字コードを返答
string.format("Hello, %s!", "Lua")  -- Cの`printf`スタイルで文字列をフォーマット
```

## API: テーブル

```lua
table.foreach(t, function(key, value) ... end) -- -- テーブル`t`のすべてのキーと値に対して、指定した関数を適用 ※5.2から削除
table.insert(t, 21)          -- テーブル`t`の末尾に値`21`を追加
table.insert(t, 4, 99)       -- テーブル`t`の4番目の位置に値`99`を挿入
table.concat(t, " ", 1, 3)  -- 指定範囲内のテーブル内のインデックスの文字列を連結し、1つの文字列として返答。文字間を繋ぐセパレータを指定することも可能。
table.sort(t, function)  -- テーブルを昇順でソート（オプションでカスタムの比較関数を指定）
table.remove(t, 4)  -- テーブル`t`の4番目の要素を削除し、削除した値を返答（後続の要素は左にシフトされる）
```

## API: 数学ライブラリ

```lua
math.abs     math.acos    math.asin       math.atan    math.atan2
math.ceil    math.cos     math.cosh       math.deg     math.exp
math.floor   math.fmod    math.frexp      math.ldexp   math.log
math.log10   math.max     math.min        math.modf    math.pow
math.rad     math.random  math.randomseed math.sin     math.sinh
math.sqrt    math.tan     math.tanh

math.sqrt(144)
math
```

## API: その他

```lua
io.output(io.open("file.txt", "w"))
io.write(x)
io.close()

for line in io.lines("file.txt")

file = assert(io.open("file.txt", "r"))
file:read()
file:lines()
file:close()
```

## Reference

http://www.lua.org/pil/13.html
http://lua-users.org/wiki/ObjectOrientedProgramming
