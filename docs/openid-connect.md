# OpenID Connect w/ Keycloak

<!-- @import "[TOC]" {cmd="toc" depthFrom=2 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [環境のセットアップ（Kong EE）](#環境のセットアップkong-ee)
- [環境のセットアップ（Kong Konnect）](#環境のセットアップkong-konnect)
- [実現する動作](#実現する動作)
  - [設定の解説](#設定の解説)
    - [Kong Gateway](#kong-gateway)
- [動作確認手順](#動作確認手順)

<!-- /code_chunk_output -->

## 環境のセットアップ（Kong EE）

`<repo-root>/examples/security` へ移動し、以下のコマンドを実行します。

```sh
docker compose up -d
```

正常に起動すると、以下のコンテナが起動されます。

```sh
NAME       IMAGE                              COMMAND                   SERVICE    CREATED         STATUS                     PORTS
database   postgres:16                        "docker-entrypoint.s…"   database   3 minutes ago   Up 3 minutes (healthy)     0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp
gateway    kong/kong-gateway:3.11             "/entrypoint.sh kong…"   gateway    3 minutes ago   Up 3 minutes (unhealthy)   127.0.0.1:8000-8002->8000-8002/tcp, 127.0.0.1:8100->8100/tcp
keycloak   quay.io/keycloak/keycloak:26.4.2   "/opt/keycloak/bin/k…"   keycloak   3 minutes ago   Up 3 minutes               127.0.0.1:8080->8080/tcp
```

| container | description                               |
| --------- | ----------------------------------------- |
| database  | Kong Gateway の設定を保持する PostgreSQL  |
| gateway   | Kong Gateway                              |
| keycloak  | Identity Provider として利用する Keycloak |

また、Kong Gateway, Keycloak の設定は `<repo-root>/examples/security/config` に存在し、コンテナの起動時に自動的に反映されるようにしてあります。

## 環境のセットアップ（Kong Konnect）

Konnect でデータプレーンを作成後、表示されるスクリプトから以下のパラメータを抜き出します。

- Control Plane, Telemetry Endpoint のサブドメイン
  - `3bfecf745a`.us.cp.konghq.com:443 であれば、 `3bfecf745a` の部分
- 証明書と秘密鍵の情報

必要なパラメータを `.env`, `<repo-root>/examples/security/.env`, `<repo-root>/examples/security/config/kong/cluster-cert` に格納します。

Kong Gateway(Konnect DP)と Keycloak を起動します。

```sh
docker compose -f compose.konnect.yaml up -d
```

## 実現する動作

Kong Gateway が OpenID Connect における Relying Party となる形で確認をします。

```mermaid
sequenceDiagram
  Client ->> Kong Gateway: API call w/ basic authentication
  Kong Gateway ->> Kong Gateway: Load basic authentication credentials
  Kong Gateway ->> Keycloak: Retrieve ID/Access Token w/ Client Credentials Flow
  Keycloak ->> Kong Gateway: Return tokens
  Kong Gateway ->> Kong Gateway: Verify tokens
  Kong Gateway ->> Upstream(httpbin): Request w/ Access Token
  Upstream(httpbin) ->> Kong Gateway: Response
  Kong Gateway ->> Client: Response
```

### 設定の解説

上記の流れを実現するために以下のような設定が事前に Kong Gateway に反映されています。

#### Kong Gateway

```yaml
_format_version: "3.0"

services:
  - name: httpbin-service
    url: https://httpbin.org
    routes:
      - name: httpbin-route
        paths:
          - /mock
        strip_path: true

plugins:
  - name: openid-connect
    service: httpbin-service
    config:
      issuer: http://keycloak:8080/realms/kong/.well-known/openid-configuration
      # for demo use only(fixed value)
      client_id:
        - kong
      # for demo use only(fixed value)
      client_secret:
        - f47ac10b-58cc-4372-a567-0e02b2c3d479
      client_auth:
        - client_secret_basic
      auth_methods:
        - client_credentials
      client_credentials_param_type:
        - header
```

いくつかポイントを解説します。

まず、Kong Gateway は、`https://httpbin.org` をプロキシするように事前設定されています。

次に、OpenID Connect プラグインについてです。`config.issuer` には OpenID Connect Discovery Endpoint を指定しています。これを指定することで、その他の `token_endpoint`, `authorization_endpoint` などの設定値を Discovery Endpoint を実行した結果から自動的に取得することができます。

次に、`client_id`, `client_secret` についてです。今回は、Keycloak の構築時に Realm の設定を自動的に行なっているため固定値が設定されています。本来であれば、Keycloak 内でクライアントの作成時に設定される `client_secret` を設定します。

![keycloak-client](./images/keycloak_client.png)

また、今回の設定ではクライアントと Kong Gateway 間の認証は IdP 側のクライアント情報に紐づいた `client_id`, `client_secret` を用いた Basic 認証で解決されます。それ以外にも、リクエスト・ボディの中に資格情報を埋め込む client_secret_post や資格情報を JWT 形式で渡すような `client_secret_jwt` なども設定できます。ここの方式は、各プロジェクトの非機能要件に依存するためその都度検討いただければ幸いです。

参考：[https://developer.konghq.com/plugins/openid-connect/reference/#schema--config-client-auth](https://developer.konghq.com/plugins/openid-connect/reference/#schema--config-client-auth)

続いて、Kong Gateway でサポートする OpenID Connect ならびにその周辺方式については、`client_credentials` のみをサポートするように設定しています。これ以外にも認可コードフローやリソースオーナーパスワードクレデンシャルフロー、セッション、クライアントが取得したアクセストークンを Kong Gateway で検証する（Bearer）方法などが設定可能です。

参考：[https://developer.konghq.com/plugins/openid-connect/reference/#schema--config-auth-methods](https://developer.konghq.com/plugins/openid-connect/reference/#schema--config-auth-methods)

## 動作確認手順

まずは、資格情報なしで Kong Gateway のエンドポイントを叩いてみます。

```sh
curl http://localhost:8000/mock/anything
```

実行結果

```sh
{"message":"Unauthorized"}
```

次に正しい資格情報を含めて Kong Gateway のエンドポイントを叩いてみます。

```sh
CREDENTIAL=$(echo -n "kong:f47ac10b-58cc-4372-a567-0e02b2c3d479" | base64)
curl http://localhost:8000/mock/anything -H "Authorization: Basic $CREDENTIAL"
```

実行結果

```sh
{
  "args": {},
  "data": "",
  "files": {},
  "form": {},
  "headers": {
    "Accept": "*/*",
    "Authorization": "Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJvckMzSUdGVHhXOTdwb01SMXZIY081aVJOYTlvdUxQMUNHcnRKZ1dwazNBIn0.eyJleHAiOjE3NjEyOTIzMjQsImlhdCI6MTc2MTI5MjAyNCwianRpIjoidHJydGNjOjkxYTg2OWExLTY3NWYtZWMzYS1jY2MxLTZkNWI5YmZmNTZhOSIsImlzcyI6Imh0dHA6Ly9rZXljbG9hazo4MDgwL3JlYWxtcy9rb25nIiwic3ViIjoiODA5OTI5MGQtYzlhZi00Y2IzLWIxYjktZjM5NTRkZjQzODM2IiwidHlwIjoiQmVhcmVyIiwiYXpwIjoia29uZyIsImFjciI6IjEiLCJhbGxvd2VkLW9yaWdpbnMiOlsiLyoiXSwic2NvcGUiOiJvcGVuaWQgZW1haWwgcHJvZmlsZSIsImNsaWVudEhvc3QiOiIxNzIuMjUuMC42IiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJzZXJ2aWNlLWFjY291bnQta29uZyIsImNsaWVudEFkZHJlc3MiOiIxNzIuMjUuMC42IiwiY2xpZW50X2lkIjoia29uZyJ9.Xi2pN3hZyWSEc0YnZzghKAjJA1LjDCMJQRyVbAKm2tQb7A_vh4M4mBERfvPjBaWrcHVUTYYQHen66DaIMWWRoe7VffANWNm7kDoSWiKkI-OOA2Y3puC4TYbElSRv4tykfxSQJMaF6X2LDUTRtqLdaDRJNJaiofTTRio8M-Yfn2jbD5QAV4-aL4lDlYrPDI4VfwkmzkijoQFTkbH3ONq7DqpM0NjjkPrk11UoAqE6lM8tzBbdFn6qt3u5nLugmlPhjf2cAWLbynsCBdBqCbQGzEZxG01lC5-YPHqDJy3NL-p9K1McMpL0XJTnzYYpva_RRdi0lPlLGvr7x-fKnBorNQ",
    "Host": "httpbin.org",
    "User-Agent": "curl/8.7.1",
    "X-Amzn-Trace-Id": "Root=1-68fb2f02-47146ca46dd1c02f33b5f031",
    "X-Forwarded-Host": "localhost",
    "X-Forwarded-Path": "/mock/anything",
    "X-Forwarded-Prefix": "/mock",
    "X-Kong-Request-Id": "37481370fb2c26287bc14d17ec280319"
  },
  "json": null,
  "method": "GET",
  "origin": "172.25.0.1, 180.131.211.150",
  "url": "https://localhost/anything"
}
```
