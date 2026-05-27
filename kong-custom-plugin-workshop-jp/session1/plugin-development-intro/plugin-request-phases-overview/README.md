## Introduction

この練習の前に、Pongoをセットアップしているものとします。

もしKong plugin templateがなければCloneしてください: https://github.com/Kong/kong-plugin.git

```shell
git clone https://github.com/Kong/kong-plugin.git
cd kong-plugin
```

## Pongoの起動

```shell
pongo up
```

異なるバージョン、イメージ、license_dataを指定するには環境変数を設定します。

```shell
KONG_VERSION=2.3.x pongo up
POSTGRES=10 KONG_VERSION=2.3.3.x pongo up
POSTGRES=10 KONG_LICENSE_DATA=<your_license_data> pongo up
```

## Serviceの公開

```shell
pongo expose
```

## Kongイメージをシェルで起動してアタッチ

```shell
pongo shell
```

また、以降の作業で出力されるカスタムプラグインのログを確認するために、以下でログを表示します。
```sh
tail -f  servroot/logs/error.log |grep myplugin
```

以下のコマンドは Kong シェルから実行する必要があります。

## データベースの初期化

```shell
kong migrations bootstrap --force
kong start
```

このタイミングで`init_worker`のログが確認できます。

## Serviceの追加

```shell
http POST :8001/services name=example-service url=http://httpbin.org
```

## RouteをServiceに追加

```shell
http POST :8001/services/example-service/routes name=example-route paths:='["/echo"]'
```

## MyPluginをServiceに追加

```shell
http -f :8001/services/example-service/plugins name=myplugin
```

## テスト

```shell
http :8000/echo/anything
```

Response:

```shell
HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Bye-World: this is on the response
Connection: keep-alive
Content-Length: 616
Content-Type: application/json
Date: Mon, 26 Aug 2024 03:13:14 GMT
Server: gunicorn/19.9.0
Via: kong/3.7.1
X-Kong-Proxy-Latency: 10
X-Kong-Request-Id: 49f36402fc39e43234549d23fe46444c
X-Kong-Upstream-Latency: 2

{
    "args": {},
    "data": "",
    "files": {},
    "form": {},
    "headers": {
        "Accept": "*/*",
        "Accept-Encoding": "gzip, deflate",
        "Hello-World": "this is on a request",
        "Host": "httpbin.org",
        "User-Agent": "HTTPie/3.2.3",
        "X-Amzn-Trace-Id": "Root=1-66cbf2ca-108decc258980bed0ff4d812",
        "X-Forwarded-Host": "localhost",
        "X-Forwarded-Path": "/echo/anything",
        "X-Forwarded-Prefix": "/echo",
        "X-Kong-Request-Id": "49f36402fc39e43234549d23fe46444c"
    },
    "json": null,
    "method": "GET",
    "origin": "127.0.0.1, 244.199.73.142",
    "url": "http://localhost/anything"
}
```

この時、ログから`access`、`body_filter`、`log`のハンドラ呼び出しが確認できます。

# 各フェーズにログエントリを追加

もう1つのターミナルで`handler.lua`を開き、ログ出力のために他のフェーズに以下を追加します。
```lua
kong.log.debug(" In phase <name of phase>")
```

# Kongシェルに戻り、Kongをリロードして最新のプラグインの変更を取り込む

```shell
kong reload
```

# テスト

```shell
http :8000/echo/anything
```

追加したものを含む、すべてのログのログエントリが表示されることを確認します。

# Clean up

シェルから抜けます。

```shell
exit
```

Pongoを停止します。

```shell
pongo down
```
