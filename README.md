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
- Microsoft Foundry プロジェクト（エンドポイント取得済み）
- gpt-5.4 モデルがデプロイ済み
- Azure CLI でログイン済み（`az login`）

### 手順

```bash
# 依存関係のインストール
pip install -r scripts/requirements.txt

# 環境変数の設定
cp .env.sample .env
# .env を編集して PROJECT_ENDPOINT 等を設定

# エージェント作成（Vector Store + ナレッジアップロード + エージェント）
python scripts/01_create_agent.py

# 動作確認
python scripts/02_test_agent.py -q "大阪出張の日当はいくら？"
```

## 評価

```bash
# バッチ評価（response_completeness / coherence / task_adherence / intent_resolution）
python scripts/03_run_evaluation.py
```

評価結果は Foundry Portal の「評価」タブで確認できます。

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
| `scripts/03_run_evaluation.py` | バッチ評価（4 評価器） |

## 評価データセット

| ファイル | 内容 |
|----------|------|
| `.foundry/datasets/accuracy-test.jsonl` | 正確性テスト（12件、query + ground_truth + context） |
