## Introduction

このラボでは、CIパイプラインでカスタムプラグインをテストし、LuarockバイナリをビルドしてGitHub Artifactsに自動的にアップロードするためのGitHub Actionsワークフローを作成します。


## Fork the repo

リポジトリの右上にある "Fork" をクリックします
![](assets/fork-repo.png)


## GitHubシークレットとしてライセンスデータを追加する（オプション）

Forkしたリポジトリの "Setting"をクリックします。
![](assets/setting.png)

左サイドバーの "Secrets" をクリックし、"New repository secret"をクリックします。
![](assets/setting2.png)

"KONG_LICENSE_DATA"という名前でシークレットを作成し、値にライセンスデータを入力します。 その後"Add secret"をクリックします。
![](assets/add-secret.png)

Comment line 17 and uncomment line 18 & 19.

## Run workflow

手動でワークフローを実行するには、"Actions"タブをクリックし、"All workflows"の下にある"CI"を選択し、"Run workflow"をクリックします。
![](assets/run-workflow.png)

または、masterブランチにプッシュしてコミットすると、ワークフローが自動的に実行されます。

## 結果の確認

パイプライン実行後、ワークフローをクリックします。
![](assets/review-result.png)

Artifactがあるはずなので、それをダウンロードします。
![](assets/review-result2.png)

ダウンロード物を解凍し、rockファイルがあることを確認します。
![](assets/review-result3.png)