## Introduction

このラボは、Kong EEのdblessデプロイにおけるカスタムプラグインの使用例です。

プラグインは、Kong EEのDB モードのデプロイと同じ方法でインストールされます。プラグイン用の Lua ファイルは Kong EE コンテナにマウントされ、ファイルは `KONG_LUA_PACKAGE_PATH` に含まれます。

### Kongの宣言的設定

Kongの宣言型構成ファイルには必要なすべてのエンティティの設定が1つのファイルに含まれ、そのファイルがKongに読み込まれるとすべての構成が置き換えられます。
カスタムプラグイン構成の場合でも、宣言型構成ファイルで宣言する必要があります。

このラボでは、`dbless_config` ディレクトリに2つの宣言型構成ファイルが用意されています。


1. `kong.yaml` = service,route

```yaml
_format_version: "3.0"
_transform: true

services:
- name: example-service
  url: http://httpbin.org
  routes:
  - name: example.route
    paths:
    - /echo
```


2. `kong_with_myplugin.yaml` = service,route,custom plugin config

```yaml
_format_version: "3.0"
_transform: true

services:
- name: example-service
  url: http://httpbin.org
  plugins:
  - name: myplugin
    config:
     remove_request_headers: 
       - accept
       - accept-encoding
  routes:
  - name: example.route
    paths:
    - /echo
```

## ラボ環境の起動

1. ライセンスファイル`license.json`が手元にあり、エンタープライズイメージを使用したい場合は以下のコマンドでライセンスを環境変数に保存してください。
```bash
export KONG_LICENSE_DATA=$(cat license.json)
```
2. .envを必要に応じて修正し読み込みます。
3. `docker-compose.yml` 内の `KONG_DECLARATIVE_CONFIG` に `kong.yaml` を設定します。
```yaml
 - KONG_DECLARATIVE_CONFIG=/opt/conf/dbless_config/kong.yaml #config without `myplugin`
 #- KONG_DECLARATIVE_CONFIG=/opt/conf/dbless_config/kong_with_myplugin.yaml #config with `myplugin`
```
4. Kongを `docker-compose up -d` で起動します

```shell
docker-compose up -d
```

## コンテナの起動確認

```shell
$ docker ps

CONTAINER ID   IMAGE                               COMMAND                  CREATED         STATUS                   PORTS                                                                                                                                                        NAMES
2e22be0bfccb   kong/kong-gateway:3.4.3.12-ubuntu   "/entrypoint.sh kong…"   3 seconds ago   Up 2 seconds (healthy)   0.0.0.0:8000-8002->8000-8002/tcp, :::8000-8002->8000-8002/tcp, 8003-8004/tcp, 0.0.0.0:8443-8445->8443-8445/tcp, :::8443-8445->8443-8445/tcp, 8446-8447/tcp   kong


```
## テスト

```shell
http :8000/echo/anything
```

Response:

```shell
$ http :8000/echo/anything
HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Connection: keep-alive
Content-Length: 578
Content-Type: application/json
Date: Thu, 19 Sep 2024 05:06:33 GMT
Server: gunicorn/19.9.0
Via: kong/3.4.3.12-enterprise-edition
X-Kong-Proxy-Latency: 43
X-Kong-Request-Id: 37a38847e561ed04e8348910e432ed2d
X-Kong-Upstream-Latency: 424

{
  "args": {},
  "data": "",
  "files": {},
  "form": {},
  "headers": {
    "Accept": "*/*",
    "Accept-Encoding": "gzip, deflate, br",
    "Host": "httpbin.org",
    "User-Agent": "HTTPie/3.2.3",
    "X-Amzn-Trace-Id": "Root=1-66ebb159-47436d6a2750f4a11bd7bff2",
    "X-Forwarded-Host": "localhost",
    "X-Forwarded-Path": "/echo/anything",
    "X-Forwarded-Prefix": "/echo",
    "X-Kong-Request-Id": "37a38847e561ed04e8348910e432ed2d"
  },
  "json": null,
  "method": "GET",
  "origin": "172.17.0.1, 202.179.128.36",
  "url": "http://localhost/anything"
}
```

## 宣言的設定 `myplugin`　を有効化

1. `docker-compose.yml` 内の `KONG_DECLARATIVE_CONFIG` に `kong_with_myplugin.yaml` を設定します。
```yaml
 #- KONG_DECLARATIVE_CONFIG=/opt/conf/dbless_config/kong.yaml #config without `myplugin`
 - KONG_DECLARATIVE_CONFIG=/opt/conf/dbless_config/kong_with_myplugin.yaml #config with `myplugin`
```

再度Kongのコンテナを `docker-compose up -d` で立ち上げます。

```shell
docker-compose up -d
```

## テスト

```shell
http :8000/echo/anything
```

Response:

```shell
$ http :8000/echo/anything

HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Bye-World: this is on the response
Connection: keep-alive
Content-Length: 555
Content-Type: application/json
Date: Thu, 19 Sep 2024 05:08:08 GMT
Server: gunicorn/19.9.0
Via: kong/3.4.3.12-enterprise-edition
X-Kong-Proxy-Latency: 21
X-Kong-Request-Id: 7854d423f5943d776e4b820660258d34
X-Kong-Upstream-Latency: 423

{
  "args": {},
  "data": "",
  "files": {},
  "form": {},
  "headers": {
    "Hello-World": "this is on a request",
    "Host": "httpbin.org",
    "User-Agent": "HTTPie/3.2.3",
    "X-Amzn-Trace-Id": "Root=1-66ebb1b8-2b5c556737aef3b617f31fd9",
    "X-Forwarded-Host": "localhost",
    "X-Forwarded-Path": "/echo/anything",
    "X-Forwarded-Prefix": "/echo",
    "X-Kong-Request-Id": "7854d423f5943d776e4b820660258d34"
  },
  "json": null,
  "method": "GET",
  "origin": "172.17.0.1, 202.179.128.36",
  "url": "http://localhost/anything"
}
```

## Cleanup
```bash
docker compose down
```
