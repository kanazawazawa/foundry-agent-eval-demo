# TravelExpense ヘルプデスク AI エージェント

架空の旅費精算システム「TravelExpense」の社内ヘルプデスク AI エージェントです。
社員からの旅費規程・システム操作・FAQ に関する質問に、ナレッジドキュメントを検索して回答します。

## アーキテクチャ

- **Microsoft Foundry** Prompt Agent（`PromptAgentDefinition`）
- **file_search** ツールで Vector Store 内のナレッジを検索
- **gpt-5.4** モデル

## セットアップ

### 前提条件

- Python 3.11+
- Azure CLI でログイン済み（`az login`）

### Azure リソースのデプロイ

Bicep テンプレートでリソースグループ・AI Services アカウント・Foundry プロジェクト・モデルデプロイメントをまとめて作成します。
デプロイのたびに新しい環境が作成されます（リソース名にランダムサフィックスが付与されます）。

```bash
# サブスクリプションスコープでデプロイ（RG・RBAC も自動作成）
az deployment sub create \
  -l swedencentral \
  -f infra/main.bicep \
  -p deployerPrincipalId=$(az ad signed-in-user show --query id -o tsv) \
  --query properties.outputs -o json
```

出力例:
```json
{
  "projectEndpoint": { "value": "https://ai-eval-xxxxx.services.ai.azure.com/api/projects/foundry-agent-eval" },
  "resourceGroupName": { "value": "rg-agent-eval-demo-xxxxx" },
  "modelDeploymentName": { "value": "gpt-5.4" }
}
```

`projectEndpoint` の値を次のステップで `.env` に設定します。

### エージェントのセットアップ

```bash
# 依存関係のインストール
pip install -r scripts/requirements.txt

# 環境変数の設定（PROJECT_ENDPOINT にデプロイ出力の projectEndpoint を設定）
cp .env.sample .env
# .env を編集: PROJECT_ENDPOINT=https://ai-eval-xxxxx.services.ai.azure.com/api/projects/foundry-agent-eval

# エージェント作成（Vector Store + ナレッジアップロード + エージェント）
python scripts/01_create_agent.py

# 動作確認
python scripts/02_test_agent.py -q "大阪出張の日当はいくら？"
```

## 評価

```bash
# バッチ評価（response_completeness / coherence）
python scripts/03_run_evaluation.py
```

評価結果は Foundry Portal の「評価」タブで確認できます。

### CI/CD（GitHub Actions）

手動トリガー（`workflow_dispatch`）で評価を実行します。
結果は Actions の **Summary** タブにレポートとして出力されます。

```
.github/workflows/eval.yml   ← ワークフロー定義
.github/eval-data.json        ← Action 用の評価データ（6件 × 2評価器）
```

#### 事前設定（GitHub リポジトリ）

Settings → Variables → Actions に以下を登録:

| Variable | 値 |
|----------|-----|
| `AZURE_CLIENT_ID` | App Registration のクライアント ID |
| `AZURE_TENANT_ID` | テナント ID |
| `AZURE_SUBSCRIPTION_ID` | サブスクリプション ID |
| `AZURE_AI_PROJECT_ENDPOINT` | デプロイ出力の `projectEndpoint` |

Azure 側で App Registration に OIDC フェデレーション資格情報と Azure AI User ロールを設定してください。

#### 実行

Actions タブ → "Agent Evaluation" → "Run workflow" で手動実行します。
実行のたびに Foundry に新しい Evaluation Run が作成され、ポータルの評価タブで時系列の品質推移を確認できます。

## ナレッジドキュメント

| ファイル | 内容 |
|----------|------|
| `knowledge/travel-expense-policy.md` | 旅費規程（17条） |
| `knowledge/system-manual.md` | TravelExpense 操作マニュアル |
| `knowledge/faq.md` | よくある質問（18問） |

## スクリプト

| ファイル | 役割 |
|----------|------|
| `scripts/01_create_agent.py` | Vector Store 作成 + ナレッジアップロード + エージェント作成 |
| `scripts/02_test_agent.py` | エージェントに質問を送って動作確認 |
| `scripts/03_run_evaluation.py` | バッチ評価（2 評価器） |

## 評価データセット

| ファイル | 内容 |
|----------|------|
| `.foundry/datasets/accuracy-test.jsonl` | 正確性テスト（6件、query + ground_truth + context） |
