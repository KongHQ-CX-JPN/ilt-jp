-- lua-resty-httpライブラリのhttpモジュールをインポート
local http = require "resty.http"

-- プラグインのメタデータを定義
local plugin = {
    PRIORITY = 1000, -- プラグインの優先度（他のプラグインとの実行順序を決定）
    VERSION = "0.1" -- プラグインのバージョン
}

-- プラグインのアクセスフェーズハンドラを定義
function plugin:access(plugin_conf)
    -- 新しいHTTPクライアントインスタンスを作成
    local client = http:new()

    -- プラグイン設定で指定された認証用URLに対してHTTPリクエストを送信
    local res, err = client:request_uri(plugin_conf.authentication_url, {
        headers = {
            ["Authorization"] = kong.request.get_header('authorization') -- クライアントリクエストのAuthorizationヘッダーを渡す
        }
    })

    -- 認証リクエストが失敗または200以外のステータスコードを返した場合
    if not res or res.status ~= 200 then
        kong.log.err("request failed: ", err) -- エラーをログに記録
        return kong.response.exit(403, "Authentication Failed") -- 403 Forbiddenステータスでアクセス拒否
    end

    -- リクエストクエリの'custId'パラメータをログ出力
    kong.log.info("query params", kong.request.get_query()['custId'])

    -- プラグイン設定で指定された認可用URLに対してHTTPリクエストを送信
    local res, err = client:request_uri(plugin_conf.authorization_url, {
        query = kong.request.get_query(), -- クライアントリクエストのクエリパラメータを渡す
        headers = {
            ["Authorization"] = kong.request.get_header('authorization') -- 再びAuthorizationヘッダーを渡す
        }
    })

    -- 認可リクエストが失敗または200以外のステータスコードを返した場合
    if not res or res.status ~= 200 then
        kong.log.err("request failed: ", err) -- エラーをログに記録
        return kong.response.exit(403, "Authorization Failed") -- 403 Forbiddenステータスでアクセス拒否
    end
end

-- プラグインを返す
return plugin

