#!/bin/bash

# スクリプトの使用方法を表示
usage() {
  echo "Usage: $0 <year> <month>"
  echo "Combines daily diary files for the specified month into a single file."
  exit 1
}

# 引数のチェック
if [ -z "$1" ] || [ -z "$2" ]; then
  usage
fi

YEAR="$1"
MONTH="$2"
DIARY_ROOT="daily_diary" # 日記のルートディレクトリ

MONTHLY_DIR="${DIARY_ROOT}/${YEAR}/monthly"
COMBINED_FILE="${MONTHLY_DIR}/${YEAR}${MONTH}.md"

echo "--- Processing ${DIARY_ROOT}/${YEAR}/${MONTH} ---"

# 対象月のディレクトリが存在しない場合はスキップ
if [ ! -d "${DIARY_ROOT}/${YEAR}/${MONTH}" ]; then
  echo "Directory ${DIARY_ROOT}/${YEAR}/${MONTH} does not exist. Skipping combine for ${YEAR}/${MONTH}."
  exit 0 # スクリプトを正常終了
fi

# monthly ディレクトリが存在しない場合は作成
mkdir -p "$MONTHLY_DIR"

# 既存の結合ファイルを削除（毎回作り直すため）
if [ -f "$COMBINED_FILE" ]; then
  rm "$COMBINED_FILE"
  echo "Removed existing combined file: $COMBINED_FILE"
fi

# ヘッダーを追加
echo "# ${YEAR}年${MONTH}月の日記" >> "$COMBINED_FILE"
echo "" >> "$COMBINED_FILE" # ヘッダーの下の空白行はそのまま残します。

# 日記ファイルを日付順に結合
find "${DIARY_ROOT}/${YEAR}/${MONTH}" -maxdepth 1 -type f -name "????????.md" | sort | while read -r file; do
  FILENAME=$(basename "$file" .md)

  # ファイル名が8桁の数字（YYYYMMDD）形式であることを確認
  if [[ "$FILENAME" =~ ^[0-9]{8}$ ]]; then
    FILE_YEAR="${FILENAME:0:4}"
    FILE_MONTH="${FILENAME:4:2}"
    FILE_DAY="${FILENAME:6:2}"

    # Rubyスクリプトを呼び出して曜日を取得
    DOW_NAME=$(ruby .github/scripts/get_day_of_week.rb "$FILE_YEAR" "$FILE_MONTH" "$FILE_DAY")

    if [ "$DOW_NAME" == "Invalid Date" ]; then
      echo "Warning: Could not determine day of week for $FILE_YEAR/$FILE_MONTH/$FILE_DAY. Skipping."
      continue # この日記ファイルの処理をスキップ
    fi

    echo "---" >> "$COMBINED_FILE"
    echo "" >> "$COMBINED_FILE"
    echo "## ${FILE_YEAR}/${FILE_MONTH}/${FILE_DAY} (${DOW_NAME})" >> "$COMBINED_FILE"
    echo "" >> "$COMBINED_FILE"

    # 元の日記ファイルの内容を読み込み、"# 日記"の見出しと、その直後の空白行だけを除外して結合
    sed -e '1{/^# 日記$/d;}' -e '2{/^$/d;}' "$file" >> "$COMBINED_FILE"
    echo "" >> "$COMBINED_FILE"
  fi
done

if [ -s "$COMBINED_FILE" ]; then
    sed -i -E ':a; /^\s*$/{$d;N;ba};' "$COMBINED_FILE"
    echo "" >> "$COMBINED_FILE"
else
    echo "Combined file is empty, no trailing newlines to remove."
fi

echo "Combined file created: $COMBINED_FILE"
