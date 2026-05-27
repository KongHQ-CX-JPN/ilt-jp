-- プラグイン名を設定
local PLUGIN_NAME = "myplugin"


-- データをスキーマに対して検証するためのヘルパー関数
local validate do
  -- Kongのテスト用ヘルパー関数をインポート
  local validate_entity = require("spec.helpers").validate_plugin_config_schema
  -- 対応するプラグインのスキーマをロード
  local plugin_schema = require("kong.plugins."..PLUGIN_NAME..".schema")

  -- validate関数を定義
  -- 引数: data（検証対象のデータ）
  -- 戻り値: 検証結果（成功/失敗）、およびエラー内容
  function validate(data)
    return validate_entity(data, plugin_schema)
  end
end

-- describeブロック: プラグインのスキーマに関するテストを記述
describe(PLUGIN_NAME .. ": (schema)", function()

  -- テスト1: 異なるリクエストヘッダーとレスポンスヘッダーが設定された場合
  it("accepts distinct request_header and response_header", function()
    -- リクエストヘッダーとレスポンスヘッダーが異なる値を設定
    local ok, err = validate({
        request_header = "My-Request-Header",
        response_header = "Your-Response",
      })
    -- エラーが発生していないことを確認
    assert.is_nil(err)
    -- 検証が成功していることを確認
    assert.is_truthy(ok)
  end)

  -- テスト2: 同じリクエストヘッダーとレスポンスヘッダーが設定された場合
  it("does not accept identical request_header and response_header", function()
    -- リクエストヘッダーとレスポンスヘッダーが同じ値を設定
    local ok, err = validate({
        request_header = "they-are-the-same",
        response_header = "they-are-the-same",
      })

    -- エラー内容を確認
    assert.is_same({
      ["config"] = {
        -- entity_checksでエラー時はinsert_entity_errorによって@entityというキーでエラーが記録される
        ["@entity"] = {
          [1] = "values of these fields must be distinct: 'request_header', 'response_header'"
        }
      }
    }, err)
    -- 検証が失敗していることを確認
    assert.is_falsy(ok)
  end)

  -- テスト3: 有効な値がremove_request_headersに設定された場合
  it("valid value for remove_request_headers", function()
    -- 有効なヘッダー名を設定
    local ok, err = validate({
        remove_request_headers = {"valid-header"},
      })
    -- エラーが発生していないことを確認
    assert.is_nil(err)
    -- 検証が成功していることを確認
    assert.is_truthy(ok)
  end)

  -- テスト4: 無効な値がremove_request_headersに設定された場合
  it("does not accept invalid value for remove_request_headers", function()
    -- 無効なヘッダー名を設定
    -- typedefs.header_name（実態はvalidate_header_name）は^[a-zA-Z0-9-_]+$のみ許可
    local ok, err = validate({
        remove_request_headers = {"they-@-#"},
      })

    -- エラー内容が期待通りであることを確認
    assert.is_same({
      ["config"] = {
        -- 個々のパラメータでエラー時はパラメータ名でエラーを確認可能。メッセージはvalidate_header_nameで定義
        ["remove_request_headers"] = {
          [1] = "bad header name 'they-@-#', allowed characters are A-Z, a-z, 0-9, '_', and '-'"
        }
      }
    }, err)
    -- 検証が失敗していることを確認
    assert.is_falsy(ok)
  end)

end)
