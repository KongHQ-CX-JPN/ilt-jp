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
CONTAINER ID   IMAGE                      COMMAND                   CREATED          STATUS                    PORTS      NAMES
b01a9afe10ca   kong/kong-gateway:latest   "/entrypoint.sh kong…"   52 seconds ago   Up 26 seconds (healthy)   0.0.0.0:8000-8002->8000-8002/tcp, [::]:8000-8002->8000-8002/tcp, 0.0.0.0:8004->8004/tcp, [::]:8004->8004/tcp, 8003/tcp, 0.0.0.0:8443-8445->8443-8445/tcp, [::]:8443-8445->8443-8445/tcp, 8446-8447/tcp   kong
1123ac58eb24   postgres:latest            "docker-entrypoint.s…"   52 seconds ago   Up 52 seconds (healthy)   5432/tcp     kong-database
```

## Serviceの追加

```shell
http POST :8001/services name=example-service url=http://httpbin.org
```

## ServiceにRouteを追加

```shell
http POST :8001/services/example-service/routes name=terminate-route paths:='["/terminate"]' protocols:='["http","https"]'
```

## ServiceにPluginを追加

```shell
http -f :8001/routes/terminate-route/plugins name=request-termination config.status_code=403 config.message="So long and thanks for all the fish\!"
```

これによりRequest Termination Pluginが有効化されます。
利用可能な設定値について以下を参照してください。
https://developer.konghq.com/plugins/request-termination/

## Test

```shell
http :8000/terminate
```

Response:

```shell
HTTP/1.1 403 Forbidden
Connection: keep-alive
Content-Length: 52
Content-Type: application/json; charset=utf-8
Date: Wed, 30 Sep 2026 04:39:16 GMT
Server: kong/3.14.0.6-enterprise-edition
X-Kong-Request-Id: 365c067a9e970173c6b65212227c6c30
X-Kong-Response-Latency: 4

{
    "message": "So long and thanks for all the fish\\!"
}
```

## Cleanup

```shell
docker-compose down -v
```
