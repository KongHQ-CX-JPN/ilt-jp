## Introduction

このラボは、Kubernetes上にKong公式Helmチャート(`kong/kong`)でData Planeがすでにインストールされている環境を前提に、カスタムプラグインのLuaコードをそのDPのPodに追加する方法を扱います。

DBモード・dblessモードではコンテナにボリュームマウントしていましたが、Helmインストールされた環境では、プラグインのコードを`ConfigMap`としてクラスタに登録し、`values.yaml`経由でDPのPodにマウントします。マウント後の`KONG_PLUGINS`環境変数への追加は、Helmチャートが自動で行います。

### 前提条件

- Kong公式Helmチャート(`kong/kong`)でData PlaneがすでにインストールされているKubernetesクラスタ（namespace: `kong`、release名: `kong`を想定）

## プラグインのConfigMap化

`kong-plugin/kong/plugins/myplugin`配下の`handler.lua`、`schema.lua`をそのまま`ConfigMap`として登録します。

```bash
kubectl create configmap kong-plugin-myplugin \
  --from-file=kong-plugin/kong/plugins/myplugin \
  -n kong
```

## values.yamlへのConfigMapの紐付け

このディレクトリの`values.yaml`に、ConfigMapとプラグイン名の対応を記載しています。

```yaml
plugins:
  configMaps:
  - pluginName: myplugin
    name: kong-plugin-myplugin
```

既存のDPのリリースに対して、この設定を追加で反映します（他の既存設定は`--reuse-values`で維持します）。

```bash
helm upgrade kong kong/kong \
  -n kong \
  --reuse-values \
  --values values.yaml
```

## Podの再起動確認

```shell
$ kubectl get pods -n kong
NAME                      READY   STATUS    RESTARTS   AGE
kong-7f9d8b6c5d-x2n9p     1/1     Running   0          30s
```

## KonnectへのカスタムプラグインSchema登録

DPがKonnect上のControl Planeと通信しているHybrid構成の場合、Service/RouteへのPlugin設定を受け付けるAdmin APIはDPではなくKonnect側にあります。Konnectが`myplugin`というプラグイン名のスキーマを知らない限り、DPにLuaコードを載せただけでは「そのようなプラグインは存在しない」というバリデーションエラーになり、Plugin設定自体を作成できません。

そのため、`schema.lua`をKonnect APIへ個別に登録し、対象Control Planeのプラグインカタログに`myplugin`を追加する必要があります。

### 注意点：サンドボックス評価と`name`のハードコード

このAPIは渡された`schema.lua`を単体でサンドボックス評価するため、`kong.plugins.myplugin.xxx`のような自作モジュールへの`require`は拒否されます（`400: require not permitted in sandbox`）。

`kong-plugin-creator`のテンプレートでは、プラグイン名を

```lua
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")
```

のようにrequireパスから動的に解決するのが既定ですが、この`(...)`はKong本体が`kong.plugins.myplugin.schema`として読み込む通常の経路でしか期待通りの値になりません。Konnect側の単体サンドボックス評価ではこの値が得られないため、このラボの`kong-plugin/kong/plugins/myplugin/schema.lua`は`plugin_name = "myplugin"`という固定文字列に書き換えてあります。Kong本体が通常どおり`require`する場合も、固定値がディレクトリ名と一致している限り動作に違いはありません。

### 登録

トークンと対象Control PlaneのIDを環境変数に設定します。

```bash
export KONNECT_TOKEN=xxxxx              # Konnectのパーソナルアクセストークン / システムアカウントトークン
export KONNECT_CONTROL_PLANE_ID=xxxxx   # 対象Control PlaneのID
```

`jq -Rs`でファイルの中身をJSON文字列としてエスケープしつつ送信します。

```bash
curl -i -X POST \
  "https://us.api.konghq.com/v2/control-planes/${KONNECT_CONTROL_PLANE_ID}/core-entities/plugin-schemas" \
  --header "Authorization: Bearer ${KONNECT_TOKEN}" \
  --header 'Content-Type: application/json' \
  --data "{\"lua_schema\": $(jq -Rs . kong-plugin/kong/plugins/myplugin/schema.lua)}"
```

### 確認

```bash
curl -i -X GET \
  "https://us.api.konghq.com/v2/control-planes/${KONNECT_CONTROL_PLANE_ID}/core-entities/plugin-schemas/myplugin" \
  --header "Authorization: Bearer ${KONNECT_TOKEN}"
```

レスポンスの`name`が`"myplugin"`になっていれば登録完了です。これでKonnect上でも`myplugin`をPluginとしてServiceやRouteに設定できるようになります。

## Service/Routeの作成

```bash
SERVICE_ID=$(http --body POST "https://us.api.konghq.com/v2/control-planes/${KONNECT_CONTROL_PLANE_ID}/core-entities/services" \
  Authorization:"Bearer ${KONNECT_TOKEN}" \
  name=example-service \
  host=httpbin.org \
  port:=80 \
  protocol=http | jq -r '.id')
```

```bash
ROUTE_ID=$(http --body POST "https://us.api.konghq.com/v2/control-planes/${KONNECT_CONTROL_PLANE_ID}/core-entities/routes" \
  Authorization:"Bearer ${KONNECT_TOKEN}" \
  name=example-route \
  paths:='["/echo"]' \
  protocols:='["http","https"]' \
  service[id]="${SERVICE_ID}" | jq -r '.id')
```

## myplugin の適用

```bash
PLUGIN_ID=$(http --body POST "https://us.api.konghq.com/v2/control-planes/${KONNECT_CONTROL_PLANE_ID}/core-entities/plugins" \
  Authorization:"Bearer ${KONNECT_TOKEN}" \
  name=myplugin \
  service[id]="${SERVICE_ID}" \
  config:='{"remove_request_headers": ["accept", "accept-encoding"]}' | jq -r '.id')
```

## テスト

Konnectで作った設定がDPに同期されるまで少し待ってから、DPのProxy Serviceにport-forwardしてテストします。

```bash
kubectl port-forward -n kong svc/kong-proxy 8000:8000
```

別ターミナルで:

```bash
http :8000/echo/anything
```

Response:

```shell
HTTP/1.1 200 OK
Content-Type: application/json

{
  "args": {},
  "data": "",
  "files": {},
  "form": {},
  "headers": {
    "Content-Type": "application/json",
    "Hello-World": "this is on a request",
    "Host": "httpbin.org",
    "User-Agent": "HTTPie/3.2.4",
    "X-Forwarded-Host": "localhost",
    "X-Forwarded-Path": "/echo/anything",
    "X-Forwarded-Prefix": "/echo",
    "X-Kong-Request-Id": "d4688124dd203b1c9206e034d0fa3876"
  },
  "json": null,
  "method": "GET",
  "origin": "127.0.0.1, 98.81.249.248",
  "url": "http://localhost/anything"
}
```

`accept`・`accept-encoding`ヘッダーが除去され、`Hello-World`リクエストヘッダーが付与された状態でhttpbinまで転送されていること、レスポンスに`Bye-World`ヘッダーが付与されていることを確認します。これで、KonnectにスキーマとPlugin設定を登録し、HelmでDPに載せたLuaコードが実際に動作することまで一通り確認できました。

## Cleanup

```bash
http DELETE "https://us.api.konghq.com/v2/control-planes/${KONNECT_CONTROL_PLANE_ID}/core-entities/plugins/${PLUGIN_ID}" \
  Authorization:"Bearer ${KONNECT_TOKEN}"

http DELETE "https://us.api.konghq.com/v2/control-planes/${KONNECT_CONTROL_PLANE_ID}/core-entities/routes/${ROUTE_ID}" \
  Authorization:"Bearer ${KONNECT_TOKEN}"

http DELETE "https://us.api.konghq.com/v2/control-planes/${KONNECT_CONTROL_PLANE_ID}/core-entities/services/${SERVICE_ID}" \
  Authorization:"Bearer ${KONNECT_TOKEN}"

curl -i -X DELETE \
  "https://us.api.konghq.com/v2/control-planes/${KONNECT_CONTROL_PLANE_ID}/core-entities/plugin-schemas/myplugin" \
  --header "Authorization: Bearer ${KONNECT_TOKEN}"

helm upgrade kong kong/kong -n kong --reuse-values --set plugins=null
kubectl delete configmap kong-plugin-myplugin -n kong
```
