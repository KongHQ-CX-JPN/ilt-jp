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

### Test 1

プラグインを有効化し"Accept" Headerを削除します。

```shell
http -f :8001/services/example-service/plugins name=myplugin config.remove_request_headers=accept
http :8000/echo/anything
```

Response:

```shell
HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Connection: keep-alive
Content-Length: 550
Content-Type: application/json
Date: Mon, 26 Aug 2024 06:50:55 GMT
Server: gunicorn/19.9.0
Via: kong/3.7.1
X-Kong-Proxy-Latency: 1
X-Kong-Request-Id: d880675551c18d29619bbe592204bb7f
X-Kong-Upstream-Latency: 5

{
    "args": {},
    "data": "",
    "files": {},
    "form": {},
    "headers": {
        "Accept-Encoding": "gzip, deflate",
        "Host": "httpbin.org",
        "User-Agent": "HTTPie/3.2.3",
        "X-Amzn-Trace-Id": "Root=1-66cc25cf-3f64c70507549227465b3621",
        "X-Forwarded-Host": "localhost",
        "X-Forwarded-Path": "/echo/anything",
        "X-Forwarded-Prefix": "/echo",
        "X-Kong-Request-Id": "d880675551c18d29619bbe592204bb7f"
    },
    "json": null,
    "method": "GET",
    "origin": "127.0.0.1, 244.199.73.142",
    "url": "http://localhost/anything"
}


```

### Test 2

プラグインを有効化し"Accept-Encoding" Headerを削除します。

```shell
http :8001/services/example-service/plugins
http DELETE :8001/services/example-service/plugins/<plugin-id>
http -f :8001/services/example-service/plugins name=myplugin config.remove_request_headers=accept-encoding
http :8000/echo/anything
```

Response:

```shell
HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Connection: keep-alive
Content-Length: 531
Content-Type: application/json
Date: Mon, 26 Aug 2024 06:53:34 GMT
Server: gunicorn/19.9.0
Via: kong/3.7.1
X-Kong-Proxy-Latency: 1
X-Kong-Request-Id: 2f101158b54b1e66f7a38d49fa50f51c
X-Kong-Upstream-Latency: 4

{
    "args": {},
    "data": "",
    "files": {},
    "form": {},
    "headers": {
        "Accept": "*/*",
        "Host": "httpbin.org",
        "User-Agent": "HTTPie/3.2.3",
        "X-Amzn-Trace-Id": "Root=1-66cc266e-759d655d06cd515f0382ae7d",
        "X-Forwarded-Host": "localhost",
        "X-Forwarded-Path": "/echo/anything",
        "X-Forwarded-Prefix": "/echo",
        "X-Kong-Request-Id": "2f101158b54b1e66f7a38d49fa50f51c"
    },
    "json": null,
    "method": "GET",
    "origin": "127.0.0.1, 244.199.73.142",
    "url": "http://localhost/anything"
}



```

### Test 3

プラグインを有効化し"Accept"と"Accept-Encoding" Headerを削除します。

```shell
http :8001/services/example-service/plugins
http DELETE :8001/services/example-service/plugins/<plugin-id>
http -f :8001/services/example-service/plugins name=myplugin config.remove_request_headers=accept config.remove_request_headers=accept-encoding
http :8000/echo/anything
```

Response:

```shell
HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Connection: keep-alive
Content-Length: 509
Content-Type: application/json
Date: Mon, 26 Aug 2024 06:55:05 GMT
Server: gunicorn/19.9.0
Via: kong/3.7.1
X-Kong-Proxy-Latency: 1
X-Kong-Request-Id: f4aa8e34c9284d10f92fad73b9b3a13b
X-Kong-Upstream-Latency: 2

{
    "args": {},
    "data": "",
    "files": {},
    "form": {},
    "headers": {
        "Host": "httpbin.org",
        "User-Agent": "HTTPie/3.2.3",
        "X-Amzn-Trace-Id": "Root=1-66cc26c9-59254dca390a42cb0e41833a",
        "X-Forwarded-Host": "localhost",
        "X-Forwarded-Path": "/echo/anything",
        "X-Forwarded-Prefix": "/echo",
        "X-Kong-Request-Id": "f4aa8e34c9284d10f92fad73b9b3a13b"
    },
    "json": null,
    "method": "GET",
    "origin": "127.0.0.1, 44.199.73.142",
    "url": "http://localhost/anything"
}


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
