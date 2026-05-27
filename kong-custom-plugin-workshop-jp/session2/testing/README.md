## Pluginのディレクトリに移動


```shell
    cd kong-plugin
```

### Pongoの起動

```shell
pongo up
```

### すべてのテストの実行

```shell
pongo run
```

### 特定の条件下でのテストの実行

```shell
KONG_VERSION=1.3.x pongo run -v -o json ./spec/myplugin/02-integration_spec.lua
```
run以降のオプションはbustedに渡される。