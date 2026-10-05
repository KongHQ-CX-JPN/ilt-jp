## Introduction

ライセンスファイル`license.json`が手元にあり、エンタープライズイメージを使用したい場合は以下のコマンドでライセンスを環境変数に保存してください。

```bash
export KONG_LICENSE_DATA=$(cat license.json)
```

.envを必要に応じて修正し読み込みます。

docker-composeを使用してKongとデータベースコンテナを起動します。docker-compose upを実行する前に、データベースのマイグレーションを実行する必要があります。

```shell
docker-compose up -d
```

## コンテナの起動確認

```shell
$ docker ps
CONTAINER ID   IMAGE                      COMMAND                   CREATED          STATUS                    PORTS                                                                                                                            NAMES
0707b6f3eace   kong/kong-gateway:latest   "/entrypoint.sh kong…"   52 seconds ago   Up 28 seconds (healthy)   0.0.0.0:8000-8002->8000-8002/tcp, [::]:8000-8002->8000-8002/tcp, 8003-8004/tcp, 0.0.0.0:8443-8445->8443-8445/tcp, [::]:8443-8445->8443-8445/tcp, 8446-8447/tcp   kong
8cd0ee91001d   postgres:latest            "docker-entrypoint.s…"   53 seconds ago   Up 52 seconds (healthy)   5432/tcp                                                                                                                           kong-database
```

## Serviceの追加

```shell
http POST :8001/services \
  name=example-service \
  url=http://httpbin.org
```

## RouteをServiceに追加

```shell
http POST :8001/services/example-service/routes \
  name=example-route \
  paths:='["/echo"]' \
  protocols:='["http","https"]'
```

## PluginをServiceに追加

```shell
http -f :8001/services/example-service/plugins \
  name=myplugin \
  config.remove_request_headers=accept \
  config.remove_request_headers=accept-encoding
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
Content-Length: 557
Content-Type: application/json
Date: Mon, 05 Oct 2026 00:17:25 GMT
Server: gunicorn/19.9.0
Via: 1.1 kong/3.14.0.6-enterprise-edition
X-Kong-Proxy-Latency: 168
X-Kong-Request-Id: e2b0e3716a34bf638a1ca6628735a75b
X-Kong-Upstream-Latency: 364

{
  "args": {},
  "data": "",
  "files": {},
  "form": {},
  "headers": {
    "Hello-World": "this is on a request",
    "Host": "httpbin.org",
    "User-Agent": "HTTPie/3.2.3",
    "X-Amzn-Trace-Id": "Root=1-66ebaa51-177d3c4d4b6c14897ef9869d",
    "X-Forwarded-Host": "localhost",
    "X-Forwarded-Path": "/echo/anything",
    "X-Forwarded-Prefix": "/echo",
    "X-Kong-Request-Id": "161e771d46e5335c42d881146ba65248"
  },
  "json": null,
  "method": "GET",
  "origin": "172.17.0.1, 202.179.128.36",
  "url": "http://localhost/anything"
}
```

## Cleanup

```sh
docker-compose down
```