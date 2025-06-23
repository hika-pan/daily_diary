#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'date'

# 日記ファイルのパスを生成
def diary_path(year, month, day)
  "diary/#{year}/#{'%02d' % month}/#{'%04d%02d%02d' % [year, month, day]}.md"
end

# 日記ファイルが存在するかチェック
def diary_exists?(year, month, day)
  File.exist?(diary_path(year, month, day))
end

# 日記ファイルのタイトルを取得（最初の行から）
def get_diary_title(year, month, day)
  path = diary_path(year, month, day)
  return nil unless File.exist?(path)

  lines = File.readlines(path, encoding: 'UTF-8')
  # "# 日記" を除いて最初の段落を取得
  content_lines = lines.drop_while { |line| line.strip.empty? || line.strip == "# 日記" }
  first_paragraph = content_lines.take_while { |line| !line.strip.empty? }

  if first_paragraph.any?
    # 最初の文を取得（句点まで）
    first_sentence = first_paragraph.join.gsub(/\n/, '').match(/^[^\n。！？]*[。！？]?/)
    return first_sentence ? first_sentence[0].strip.gsub(/^　+/, '') : nil
  end

  nil
end

# 日付の日本語表記を取得
def japanese_date(year, month, day)
  date = Date.new(year, month, day)
  day_names = %w[日 月 火 水 木 金 土]
  "#{year}/#{month}/#{day}(#{day_names[date.wday]})"
end

# 最新の日記を取得
def get_latest_diary
  today = Date.today

  # 今日から過去30日間をチェック
  30.times do |i|
    check_date = today - i
    if diary_exists?(check_date.year, check_date.month, check_date.day)
      return {
        year: check_date.year,
        month: check_date.month,
        day: check_date.day,
        title: get_diary_title(check_date.year, check_date.month, check_date.day)
      }
    end
  end

  nil
end

# 最新1週間の日記を取得
def get_recent_diaries
  today = Date.today
  recent_diaries = []

  # 過去7日間をチェック
  7.times do |i|
    check_date = today - i
    if diary_exists?(check_date.year, check_date.month, check_date.day)
      recent_diaries << {
        year: check_date.year,
        month: check_date.month,
        day: check_date.day,
        title: get_diary_title(check_date.year, check_date.month, check_date.day)
      }
    end
  end

  recent_diaries
end

# 月次ファイルのリストを取得
def get_monthly_diaries
  monthly_files = Dir.glob('diary/*/monthly/*.md').sort.reverse
  monthly_files.map do |file|
    match = file.match(/diary\/(\d{4})\/monthly\/(\d{4})(\d{2})\.md/)
    if match
      year, month = match[1].to_i, match[3].to_i
      {
        year: year,
        month: month,
        path: file,
        title: "#{year}年#{month}月の日記"
      }
    end
  end.compact
end

# README.mdを生成
def generate_readme
  latest = get_latest_diary
  recent = get_recent_diaries
  monthly = get_monthly_diaries

  readme_content = <<~README
    ---
    layout: default
    title: "毎日書く日記"
    description: "毎日の出来事を記録した日記サイトです。最新の日記や過去の記録をご覧いただけます。"
    ---

    # dairy_diary

    毎日書く日記

    ## 最新の日記

  README

  if latest
    title_text = latest[:title] ? " - #{latest[:title]}" : ""
    readme_content += "- [#{japanese_date(latest[:year], latest[:month], latest[:day])}](#{diary_path(latest[:year], latest[:month], latest[:day])})#{title_text}\n\n"
  else
    readme_content += "現在、公開されている日記はありません。\n\n"
  end

  readme_content += "## 最新1週間の日記\n\n"

  if recent.any?
    recent.each do |diary|
      title_text = diary[:title] ? " - #{diary[:title]}" : ""
      readme_content += "- [#{japanese_date(diary[:year], diary[:month], diary[:day])}](#{diary_path(diary[:year], diary[:month], diary[:day])})#{title_text}\n"
    end
    readme_content += "\n"
  else
    readme_content += "最近の日記はありません。\n\n"
  end

  readme_content += "## その他の日記\n\n"
  readme_content += "### 月次まとめ\n\n"

  if monthly.any?
    monthly.first(6).each do |diary|
      readme_content += "- [#{diary[:title]}](#{diary[:path]})\n"
    end
    readme_content += "\n"
  end

  readme_content += "### 週末の記録\n\n"
  readme_content += "- [週末やったこと](diary/2025/weekend/weekend_diary.md)\n"
  readme_content += "- [週末分析レポート](diary/2025/weekend/analysis_report.md)\n\n"

  readme_content += "## リンク\n\n"
  readme_content += "- [GitHub Pages](https://hika-pan.github.io/daily_diary/)\n"
  readme_content += "- [GitHubリポジトリ](https://github.com/hika-pan/daily_diary)\n\n"

  readme_content += "## 管理者用\n\n"
  readme_content += "Gemini API ダッシュボード <https://aistudio.google.com/apikey>\n"

  readme_content
end

# メイン処理
if __FILE__ == $0
  readme_content = generate_readme
  File.write('README.md', readme_content, encoding: 'UTF-8')
  File.write('index.md', readme_content, encoding: 'UTF-8')
  puts "README.md and index.md updated successfully"
end
