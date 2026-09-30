## Introduction
.envを必要に応じてKong EEライセンス、Kongのバージョン、Postgresのバージョンについて更新します。
ライセンスが必要な場合は以下のようにして環境変数に設定します。
```bash
export KONG_LICENSE_DATA=$(cat license.json)
```

localhostを使ってKong Gatewayにアクセスしない場合はdocker-compose.yml内のKONG_ADMIN_GUI_URLを以下のようにアクセス先アドレスに変更します。
```sh
sed -i 's/localhost/<Your Host IP>/g' docker-compose.yml
```
docker-composeを使用してKong GatewayとDBコンテナを起動します。

```shell
docker-compose up -d
```

## コンテナの起動確認

```shell
$ docker ps 
CONTAINER ID   IMAGE                      COMMAND                   CREATED          STATUS                            PORTS                     NAMES
06a3232cdde0   kong/kong-gateway:latest   "/entrypoint.sh kong…"   26 seconds ago   Up 2 seconds (health: starting)   0.0.0.0:8000-8002->8000-8002/tcp, [::]:8000-8002->8000-8002/tcp, 0.0.0.0:8004->8004/tcp, [::]:8004->8004/tcp, 8003/tcp, 0.0.0.0:8443-8445->8443-8445/tcp, [::]:8443-8445->8443-8445/tcp, 8446-8447/tcp   kong
4ba0dfb11a7a   postgres:latest            "docker-entrypoint.s…"   26 seconds ago   Up 25 seconds (healthy)           5432/tcp                    kong-database
```

## Serviceの追加

```shell
http POST :8001/services name=example-service url=http://httpbin.org
```

## ServiceにRouteを追加

```shell
http POST :8001/services/example-service/routes name=transform-route paths:='["/transform"]' protocols:='["http","https"]'
```

## ServiceにPluginを追加

```shell
http -f POST :8001/services/example-service/plugins name=request-transformer config.remove.headers=accept config.remove.querystring=custId config.remove.body=custId
```
Request Transformer Pluginを有効にし、`accept` ヘッダ、クエリ文字列の `custId`、および本文の `custId` を削除します。
利用可能な設定値について以下を参照してください。
https://developer.konghq.com/plugins/request-transformer/

## Test

```shell
http :8000/transform/anything custId==200 a==100 
```

Response:

```shell
HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Connection: keep-alive
Content-Length: 593
Content-Type: application/json
Date: Wed, 30 Sep 2026 04:44:31 GMT
Server: gunicorn/19.9.0
Via: 1.1 kong/3.14.0.6-enterprise-edition
X-Kong-Proxy-Latency: 56
X-Kong-Request-Id: abf94a08bb3e00125651120b73456e32
X-Kong-Upstream-Latency: 345

{
    "args": {
        "a": "100"
    },
    "data": "",
    "files": {},
    "form": {},
    "headers": {
        "Accept-Encoding": "gzip, deflate, zstd",
        "Host": "httpbin.org",
        "User-Agent": "HTTPie/3.2.4",
        "X-Amzn-Trace-Id": "Root=1-6abc93af-5f77d6dc6317d9cd7aa776cf",
        "X-Forwarded-Host": "localhost",
        "X-Forwarded-Path": "/transform/anything",
        "X-Forwarded-Prefix": "/transform",
        "X-Kong-Request-Id": "abf94a08bb3e00125651120b73456e32"
    },
    "json": null,
    "method": "GET",
    "origin": "192.168.64.1, 224.215.116.147",
    "url": "http://localhost/anything?a=100"
}
```

## Cleanup

```shell
docker-compose down --volumes
```
