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
CONTAINER ID   IMAGE                        COMMAND               CREATED              STATUS              PORTS                NAMES
50db1a0d3da8   postgres:13-alpine           "postgres"            About a minute ago   Up About a minute                        kong-database
dbac4b654807   kong/kong-gateway:3.4.3.12   "kong docker-start"   About a minute ago   Up About a minute   8000/tcp, 8443/tcp   kong
```

## Serviceの追加

```shell
http POST :8001/services name=example-service url=http://httpbin.org
```

## ServiceにRouteを追加

```shell
http POST :8001/services/example-service/routes name=terminate-route paths:='["/terminate"]'
```

## ServiceにPluginを追加

```shell
http -f :8001/routes/terminate-route/plugins name=request-termination config.status_code=403 config.message="So long and thanks for all the fish\!"
```

これによりRequest Termination Pluginが有効化されます。
利用可能な設定値について以下を参照してください。
https://docs.konghq.com/hub/kong-inc/request-termination/

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
Date: Fri, 23 Aug 2024 01:51:32 GMT
Server: kong/3.4.3.12-enterprise-edition
X-Kong-Request-Id: 2acf400aa0135265a4dce12ad48f2820
X-Kong-Response-Latency: 2

{
    "message": "So long and thanks for all the fish\\!"
}
```

## Cleanup

```shell
docker-compose down -v
```
