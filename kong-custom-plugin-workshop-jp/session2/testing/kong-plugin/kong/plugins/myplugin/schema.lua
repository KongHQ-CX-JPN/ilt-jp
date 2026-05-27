local typedefs = require "kong.db.schema.typedefs"

-- module名からプラグイン名を取得
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

local schema = {
  name = plugin_name,
  fields = {
    -- 'fields' 配列は、Kong によって定義された最上位のフィールドエントリ
    { consumer = typedefs.no_consumer },  -- このプラグインはコンシューマ単位で設定できない（認証プラグインでは一般的）
    { protocols = typedefs.protocols_http },
    { config = {
        -- 'config' レコードは、プラグインスキーマ内のカスタム部分
        type = "record",
        fields = {
          -- 一部カスタマイズされた、定義済みの標準フィールド（typedef）
          { request_header = typedefs.header_name {
              required = true,
              default = "Hello-World" } },
          { response_header = typedefs.header_name {
              required = true,
              default = "Bye-World" } },
          { ttl = { -- 独自定義のフィールド
              type = "integer",
              default = 600,
              required = true,
              gt = 0, }}, -- 値に制約を追加

          { remove_request_headers = { -- 新しいフィールドを追加
            type = "array",
            elements = typedefs.header_name}},
        },
        entity_checks = {
          -- 複数のフィールドにまたがるバリデーションルールを追加
          -- 以下のルールは常に真になるため無意味（両方必須なので）
          { at_least_one_of = { "request_header", "response_header" }, },
          -- 両方のヘッダー名が同じであってはならないというルールを指定
          { distinct = { "request_header", "response_header"} },
        },
      },
    },
  },
}


return schema
