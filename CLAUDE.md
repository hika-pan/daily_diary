# CLAUDE.md

このファイルは Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

**重要**: このファイルを編集する際は、日本語で記述すること。このリポジトリは日本語の日記リポジトリであるため、すべてのドキュメントは日本語で記述する必要があります。

## プロジェクト概要

これは日本語で書かれた個人日記リポジトリ（`dairy_diary`）で、日々の日記エントリを自動的に処理し、月次サマリーに結合します。リポジトリには日記処理と Gemini API を使用した週末活動分析のための自動化 GitHub ワークフローが含まれています。

## リポジトリ構成

- `diary/YYYY/MM/YYYYMMDD.md` - 日本語の日々の日記エントリ
- `diary/YYYY/monthly/YYYYMM.md` - 自動生成された月次統合日記
- `diary/YYYY/weekend/` - 週末活動の追跡と分析
- `.github/scripts/` - 自動化スクリプト（Ruby と Bash）
- `.github/workflows/` - 自動化のための GitHub Actions
- `docs/adr/` - アーキテクチャ決定記録（現在は空）

## コマンド

### 手動での日記統合
```bash
# 特定の月の日記を統合
.github/scripts/combine_diaries.sh 2025 06

# 必要に応じてスクリプトを実行可能にする
chmod +x .github/scripts/*.sh
```

### 週末分析
```bash
# 手動で週末分析を実行（GEMINI_API_KEY が必要）
ruby .github/scripts/analyze_weekend.rb
```

## 主要な自動化機能

1. **月次日記統合**: 日記ファイルがプッシュされると、GitHub Actions が自動的に日々の日記ファイルを月次サマリーに統合
2. **週末分析**: 毎週月曜日にスケジュールされた GitHub Action が Gemini API を使用して週末活動を分析
3. **日付処理**: Ruby スクリプトが日記エントリの曜日を決定

## ファイル命名規則

- 日々の日記: `YYYYMMDD.md`（例: `20250621.md`）
- 月次統合: `YYYYMM.md`（例: `202506.md`）
- すべての日記コンテンツは一貫したフォーマットの日本語

## 権限設定

Claude Code は `.claude/settings.local.json` で制限されたbash権限が設定されています：
- 許可: `grep`、`find`、`ls`、および日記統合スクリプト
- 拒否: デフォルトで他のすべてのbashコマンド

## GitHub ワークフロー

- `ci-combine-diary.yaml`: 日々の日記を月次ファイルに自動統合
- `weekend-analysis.yml`: Gemini API を使用した週末活動の週次分析
- 両方のワークフローは GitHub Actions ボットを使用して自動的に変更をコミット