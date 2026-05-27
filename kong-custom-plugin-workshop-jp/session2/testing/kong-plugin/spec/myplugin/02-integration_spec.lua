-- テストヘルパー関数をインポート
local helpers = require "spec.helpers"
-- プラグイン名を定義
local PLUGIN_NAME = "myplugin"
-- 使用するデータベースストラテジーを指定
local strategy = "postgres"

-- describeブロック: プラグインの動作に関するテストを記述
describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    -- クライアントを保持する変数を定義
    local client

    -- lazy_setupブロック: テスト実行前にKongを起動
    lazy_setup(function()
        -- テスト用データベースとプラグインをセットアップ（プラグインのスキーマのロード）
        local bp = helpers.get_db_utils(
            strategy == "off" and "postgres" or strategy, 
            nil, 
            {PLUGIN_NAME})

        -- テスト用ルートを作成
        -- サービスを作成する必要はなく、デフォルトサービスが使用される（リクエストをエコーする動作）
        local route1 = bp.routes:insert({
            hosts = {"test1.com"}
        })
        -- 作成したルートにプラグインを適用
        bp.plugins:insert{
            name = PLUGIN_NAME,
            route = {
                id = route1.id
            },
            config = {}
        }

        -- Kongの起動
        assert(helpers.start_kong({
            -- 使用するデータベースストラテジー
            database = strategy,
            -- カスタムNginxテンプレートを指定
            nginx_conf = "spec/fixtures/custom_nginx.template",
            -- プラグインをロード
            plugins = "bundled," .. PLUGIN_NAME,
            -- ストラテジーが"off"の場合は宣言的設定を作成
            declarative_config = strategy == "off" 
              and helpers.make_yaml_file() 
              or nil
        }))
    end)

    -- lazy_teardown: テスト環境のクリーンアップ
    lazy_teardown(function()
        helpers.stop_kong(nil, true)
    end)

    -- before_eachブロック: テスト実行前にクライアントを初期化
    before_each(function()
        client = helpers.proxy_client()
    end)

    -- after_eachブロック: テスト実行後にクライアントをクローズ
    after_each(function()
        if client then
            client:close()
        end
    end)

    -- describeブロック: リクエストヘッダーとレスポンスヘッダーのテストを記述
    describe("request", function()
        -- テスト1: "hello-world"ヘッダーを確認
        it("gets a 'hello-world' header", function()
            -- プロキシ経由でリクエストを送信
            local r = client:get("/request", {
                headers = {
                    host = "test1.com"
                }
            })
            -- レスポンスが成功し、ステータスコード200を返すことを確認
            assert.response(r).has.status(200)
            -- モックサーバーがエコーしたリクエストヘッダーに"hello-world"が含まれることを確認
            local header_value = assert.request(r).has.header("hello-world")
            -- "hello-world"ヘッダーの値が期待通りであることを確認
            assert.equal("this is on a request", header_value)
        end)
    end)

    -- describeブロック: レスポンス関連のテストを記述
    describe("response", function()
        -- テスト2: "bye-world"ヘッダーを確認
        it("gets a 'bye-world' header", function()
            -- プロキシ経由でリクエストを送信
            local r = client:get("/request", {
                headers = {
                    host = "test1.com"
                }
            })
            -- レスポンスが成功し、ステータスコード200を返すことを確認
            assert.response(r).has.status(200)
            -- レスポンスヘッダーに"bye-world"が含まれることを確認
            local header_value = assert.response(r).has.header("bye-world")
            -- "bye-world"ヘッダーの値が期待通りであることを確認
            assert.equal("this is on the response", header_value)
        end)
    end)

end)
