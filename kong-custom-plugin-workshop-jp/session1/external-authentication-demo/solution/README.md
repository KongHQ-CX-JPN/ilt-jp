### プラグインのディレクトリに移動
```shell
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

以下のコマンドは Kong シェルから実行する必要があります。

## データベースの初期化

```shell
kong migrations bootstrap --force
kong start
```

## Serviceの追加

```shell
http POST :8001/services name=example-service url=http://httpbin.org
```

## RouteをServiceに追加

```shell
http POST :8001/services/example-service/routes name=example-route paths:='["/echo"]'
```

## MyPluginをServiceに追加

デフォルトの認証URLは http://httpbin.org/status/200 にセットされています。

```shell
http -f :8001/services/example-service/plugins name=myplugin
http :8000/echo/anything
```

Response:

```shell
HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Connection: keep-alive
Content-Length: 572
Content-Type: application/json
Date: Mon, 26 Aug 2024 07:36:54 GMT
Server: gunicorn/19.9.0
Via: kong/3.7.1
X-Kong-Proxy-Latency: 7
X-Kong-Request-Id: b6fd7469a115251c615b0b0d8049ee2d
X-Kong-Upstream-Latency: 3

{
    "args": {},
    "data": "",
    "files": {},
    "form": {},
    "headers": {
        "Accept": "*/*",
        "Accept-Encoding": "gzip, deflate",
        "Host": "httpbin.org",
        "User-Agent": "HTTPie/3.2.3",
        "X-Amzn-Trace-Id": "Root=1-66cc3096-51298f265406de1f1680508e",
        "X-Forwarded-Host": "localhost",
        "X-Forwarded-Path": "/echo/anything",
        "X-Forwarded-Prefix": "/echo",
        "X-Kong-Request-Id": "b6fd7469a115251c615b0b0d8049ee2d"
    },
    "json": null,
    "method": "GET",
    "origin": "127.0.0.1, 44.199.73.142",
    "url": "http://localhost/anything"
}

```

403が返ってくる認証URLに変更します。

```shell
http :8001/services/example-service/plugins
http DELETE :8001/services/example-service/plugins/<plugin-id>
http -f :8001/services/example-service/plugins name=myplugin config.authentication_url=http://httpbin.org/status/403
http :8000/echo/anything
```

Response:

```shell
HTTP/1.1 403 Forbidden
Connection: keep-alive
Content-Length: 21
Date: Mon, 26 Aug 2024 07:38:28 GMT
Server: kong/3.7.1
X-Kong-Request-Id: 363c830a7c03543008c0681103227f4c
X-Kong-Response-Latency: 4

Authentication Failed
```

# Clean up

シェルから抜けます。

```shell
exit
```

Pongoを停止します。

```shell
pongo down
```

