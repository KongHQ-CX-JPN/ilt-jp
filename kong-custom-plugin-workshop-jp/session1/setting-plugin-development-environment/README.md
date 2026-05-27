## Requirements

Pongoを実行するために以下が必要となります。

- `docker-compose` (とそのための `docker`)
- `curl`
- `realpath`, Macであれば[`coreutils`](https://www.gnu.org/software/coreutils/coreutils.html)のインストールが必要。brewが使えるなら以下でインストール可能。
  ```
  brew install coreutils
  ```
- あなたの環境に応じて、いくつかの[環境変数](#environment-variables)を設定する必要があります。

## kong plugin templateのclone (カレントディレクトリのものを使う場合は不要)

```shell
git clone https://github.com/Kong/kong-plugin
cd kong-plugin
```

## PongのDownloadとsetup

```shell
PATH=$PATH:~/.local/bin
git clone https://github.com/Kong/kong-pongo.git
mkdir -p ~/.local/bin
ln -s $(realpath kong-pongo/pongo.sh) ~/.local/bin/pongo
```

## 環境変数

```shell
KONG_VERSION テストイメージのビルドに使用するKongのバージョン。
(注：パッチバージョンに'x'を指定すると、最新のパッチバージョンが適用されます。)

KONG_IMAGE テストイメージを構築する際に使用するベースとなるKongのコンテナイメージ。

KONG_LICENSE_DATA Kong Enterpriseライセンスのjsonデータ。

POSTGRES 使用するPostgres依存のバージョン (default 9.5)
CASSANDRA 使用するCassandra依存関係のバージョン (default 3.9)
REDIS 使用するRedis依存のバージョン (default 5.0.4)
```

### コマンド実行例

```shell
pongo run
```
```sh
KONG_VERSION=1.3.x pongo run -v -o gtest ./spec/myplugin/02-access_spec.lua
```
```sh
POSTGRES=10 KONG_VERSION=2.3.x pongo run
```
```sh
pongo down
```

## 実行する

以下を実行してテストが実行されることを確認します。
```shell
cd kong-plugin
pongo run --no-cassandra
```

少し複雑な実行例。

```shell
# Kongの特定のバージョンを指定し、
# -vと-o gtestは以下のような形でbustedの引数を渡す
# 'bin/busted --helper=/pongo/busted_helper.lua -v -o # gtest /kong-plugin/spec'
KONG_VERSION=3.4.0 pongo run -v -o gtest ./spec

# .x'を使ってKongリリースの最新パッチバージョンに対して実行する。
KONG_VERSION=3.4.x pongo run -v -o gtest ./spec
```

上記のコマンド（`pongo run`）は自動的にテストイメージをビルドし、テスト環境を起動します。終了したら、テスト環境は次のようにして取り壊すことができます。

```shell
pongo down
```

## Test dependencies

Pongo では、テストに使う依存関係のセットを使うことができます。それぞれ`--[dependency_name]` または`--no-[dependency-name]` を `pongo up`, `pongo restart`, `pongo run` コマンドのオプションとして指定します。
依存関係を指定する別の方法は`.pongo/pongorc` ファイルに追加することです（下記参照）。

利用可能な依存関係は以下の通りです：

- **Postgres** Kongのデータストア (デフォルトで指定される)

  - `--no-postgres`で無効化できる
  - `POSTGRES`環境変数でバージョン指定できる

- **grpcbin**  grpcのバックエンドのモック

  - `--grpcbin`で有効化できる
  - エンジンは[moul/grpcbin](https://github.com/moul/grpcbin)
  - 環境内からは以下でアクセスできる
    - `grpcbin:9000` grpc over http
    - `grpcbin:9001` grpc over http+tls

- **Redis** キーバリューストア

  - `--redis`で有効化できる
  - `REDIS`環境変数でバージョン指定できる
  - 環境内から`redis:6379`でアクセスできる。
    ※他環境への移行性の観点から、test specからはヘルパーモジュールを使って`helpers.redis_host`フィールドと`6379`ポートを使ってアクセスすべき
    Example:
    ```shell
    local helpers = require "spec.helpers"
    local redis_host = helpers.redis_host
    local redis_port = 6379
    ```

- **Squid** (forward-proxy)

  - `--squid`で有効化できる
  - `SQUID`環境変数でバージョン指定できる
  - 環境内から`squid:3128`でアクセスできる。
    基本的には以下のように標準的な環境変数として設定される。

    - `http_proxy=http://squid:3128/`
    - `https_proxy=http://squid:3128/`

    設定には、ベーシック認証設定と1ユーザーが付属している。

    - username: `kong`
    - password: `king`

    `.mockbin.org`というドメインを除いて、すべてのアクセスはプロキシによって認証される。
    これはホワイトリストに登録されている。

    プロキシを使ったいくつかの実行例：

    ```shell
    # クリーンな環境で、squidを起動しシェルを立ち上げる
    pongo down
    pongo up --squid --no-postgres --no-cassandra
    pongo shell

    # httpbin (http)に認証付きでアクセス
    http --proxy=http:http://kong:king@squid:3128 --proxy=https:http://kong:king@squid:3128 http://httpbin.org/anything

    # httpsも同様
    http --proxy=http:http://kong:king@squid:3128 --proxy=https:http://kong:king@squid:3128 https://httpbin.org/anything

    # 認証なしでホワイトリストにある mockbin.org (http)にアクセス
    http --proxy=http:http://squid:3128 --proxy=https:http://squid:3128 http://mockbin.org/request

    # httpsも同様
    http --proxy=http:http://squid:3128 --proxy=https:http://squid:3128 https://mockbin.org/request
    ```

### 依存関係のデフォルト値の設定
デフォルト値はプラグインによっては利用せず、依存関係によっては（例えばCassandra）テストが遅くなることもあります。
そこで、プロジェクトやプラグインごとにデフォルト設定を上書きするために、`.pongo/pongorc`ファイルをプロジェクトに追加します。

ファイルのフォーマットはとてもシンプルです。各行には1つのコマンドラインオプションが含まれています。例えば、PostgresとRedisだけが必要なプラグイン用の`.pongo/pongorc`ファイルは以下になります。

```shell
--redis
```

### 依存関係のトラブルシューティング

依存関係のあるコンテナが問題を起こしているときは、`pongo logs` コマンドを使ってログにアクセスすることができます。
このコマンドは `docker-compose logs` と同じですが、Pongo環境でのみ動作します。
コマンドに指定された追加オプションは `docker-compose logs` コマンドにそのまま渡されます。

いくつかの実行例：

```shell
# 最新のlogの表示
pongo logs

# tailで最新のlogを表示
pongo logs -f

# Postgresの依存関係に関する最新のログをtailで表示
pongo logs -f postgres
```

## logへのアクセス
テストを実行する場合、作業ディレクトリは`./servroot`に設定されます。

エラーログ（printまたはngx.logステートメントが保存される場所）を追跡するには、`tail`コマンドを使用します。

```shell
    pongo tail
```

## サービスポートへの直接のアクセス
ホストやデータストアからKongに直接アクセスするには、`pongo expose`コマンドを使って内部ポートをホストに公開します。

これにより、例えば5432番ポートのPostgresに接続してデータベースの内容を検証することができます。また、`pongo shell`を実行して手動でKongを起動すると、GUIを含む通常のKongポートすべてにホストからアクセスできます。

これは別のコンテナとして実装されており、そのコンテナはすべてのポートを開き、docker network上で実際のサービスコンテナに中継します（この理由は、通常のPongoの実行はホスト上ですでに使われているポートに干渉しないためです。）

これは技術的には「依存関係」なので、依存関係として指定することもできます。

```shell
    pongo up
    pongo expose
```

これは以下と等価となります。

```shell
    pongo up --expose
```

`pongo expose --help`でさらなる説明が確認できます。

## Cleanup

クリーンアップするには以下を実行します。

```shell
pongo down
```

最新の情報は以下から確認できます。
https://github.com/Kong/kong-pongo/
