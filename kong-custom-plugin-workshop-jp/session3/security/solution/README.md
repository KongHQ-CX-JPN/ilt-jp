## Introduction

ライセンスファイル`license.json`が手元にあり、エンタープライズイメージを使用したい場合は以下のコマンドでライセンスを環境変数に保存してください。

```bash
export KONG_LICENSE_DATA=$(cat license.json)
```

.envを必要に応じて修正し読み込みます。

docker-composeを使用してKong、データベースコンテナ、認証サービスコンテナを起動します。
```shell
docker compose -f docker-compose-kong.yml -f docker-compose-auth-service.yml up -d --build
```

## コンテナの起動確認


```shell
$ docker ps

CONTAINER ID   IMAGE                              COMMAND                  CREATED              STATUS                        PORTS                                                                                                                                         NAMES
ff9461ad3c04   auth-service                       "docker-entrypoint.s…"   9 seconds ago        Up 8 seconds                  0.0.0.0:3000->3000/tcp, :::3000->3000/tcp                                                                                                     solution_auth-service_1
436a20d1c0f7   kong/kong-gateway:2.3.3.1-alpine   "/docker-entrypoint.…"   9 seconds ago        Up 8 seconds (healthy)        0.0.0.0:8000-8004->8000-8004/tcp, :::8000-8004->8000-8004/tcp, 0.0.0.0:8443-8445->8443-8445/tcp, :::8443-8445->8443-8445/tcp, 8446-8447/tcp   kong
c0e510fe82cc   postgres:9.5-alpine                "docker-entrypoint.s…"   About a minute ago   Up About a minute (healthy)   5432/tcp                                                                                                                                      kong-database
```

## Serviceの追加

```shell
http POST :8001/services name=example-service \
    url=http://httpbin.org
```

## RouteをServiceに追加

```shell
http POST :8001/services/example-service/routes \
    name=example-route \
    paths:='["/echo"]'
```

## PluginをServiceに追加

```shell
http -f POST :8001/services/example-service/plugins \
    name=myplugin
```

## 認証サービスのログ確認準備

別の端末で、auth-serviceコンテナのログを開き、Kongプラグインからの呼び出しを表示します。

```shell
docker-compose -f docker-compose-kong.yml -f docker-compose-auth-service.yml logs -f auth-service
```

## テスト 1 - 有効な認証トークンとcustomerIdを指定:

ヘッダに`Authorization:token1`を付加し、クエリに`custId=customer1`を指定
```shell
http :8000/echo/anything Authorization:token1 custId==customer1
```

Response:

```shell
HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Connection: keep-alive
Content-Length: 658
Content-Type: application/json
Date: Fri, 20 Sep 2024 13:33:07 GMT
Server: gunicorn/19.9.0
Via: kong/3.4.3.12-enterprise-edition
X-Kong-Proxy-Latency: 479
X-Kong-Request-Id: 53ef646881d2810d8b671641e86afd2f
X-Kong-Upstream-Latency: 423

{
  "args": {
    "custId": "customer1"
  },
  "data": "",
  "files": {},
  "form": {},
  "headers": {
    "Accept": "*/*",
    "Accept-Encoding": "gzip, deflate, br",
    "Authorization": "token1",
    "Host": "httpbin.org",
    "User-Agent": "HTTPie/3.2.3",
    "X-Amzn-Trace-Id": "Root=1-66ed7993-6f9cc29b543ae9d06544a0f6",
    "X-Forwarded-Host": "localhost",
    "X-Forwarded-Path": "/echo/anything",
    "X-Forwarded-Prefix": "/echo",
    "X-Kong-Request-Id": "53ef646881d2810d8b671641e86afd2f"
  },
  "json": null,
  "method": "GET",
  "origin": "192.168.65.1",
  "url": "http://localhost/anything?custId=customer1"
}
```

## テスト 2 - 有効な認証トークンと無効なcustomerIdを指定:

ヘッダに`Authorization:token2`を付加し、クエリに`custId=customer5`を指定
```shell
http :8000/echo/anything Authorization:token2 custId==customer5
```

Response:

```shell
HTTP/1.1 403 Forbidden
Connection: keep-alive
Content-Length: 20
Date: Fri, 20 Sep 2024 13:33:41 GMT
Server: kong/3.4.3.12-enterprise-edition
X-Kong-Request-Id: 47e547615ed6150bac54cc7b19df8419
X-Kong-Response-Latency: 6

Authorization Failed
```

## テスト 3 - 無効な認証トークンと有効な顧客IDを指定:

ヘッダに`Authorization:token5`を付加し、クエリに`custId=customer3`を指定
```shell
http :8000/echo/anything Authorization:token5 custId==customer3
```

Response:

```shell
HTTP/1.1 401 Unauthorized
Connection: keep-alive
Content-Length: 21
Date: Tue, 10 Dec 2024 09:18:42 GMT
Server: kong/3.4.3.12-enterprise-edition
X-Kong-Request-Id: bdf76e4dcfaa9149e2fb2424ac038901
X-Kong-Response-Latency: 4

Authentication Failed
```

## Cleanup

```shell
docker compose -f docker-compose-kong.yml -f docker-compose-auth-service.yml down -v
```