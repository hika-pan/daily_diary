#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'time'

class WeekendAnalyzer
  def initialize(api_key)
    @api_key = api_key
    @base_url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent'
  end

  def read_weekend_diary(file_path)
    File.read(file_path, encoding: 'utf-8')
  rescue Errno::ENOENT
    puts "Error: #{file_path} が見つかりません"
    ''
  end

  def extract_activities(diary_content)
    activities = []
    diary_content.split("\n").each do |line|
      next unless line.include?('|') && !line.include?('---|') && !line.strip.empty?

      parts = line.split('|').map(&:strip)
      next unless parts.length >= 3 && !parts[1].empty? && !parts[2].empty?

      date_str = parts[1]
      activity = parts[2]
      next if date_str == '日付' || activity == '予定'

      activities << {
        'date' => date_str,
        'activity' => activity
      }
    end

    activities
  end

  def analyze_with_gemini(activities)
    activities_text = activities.map do |act|
      "#{act['date']}: #{act['activity']}" unless act['activity'].empty?
    end.compact.join("\n")

    prompt = <<~PROMPT
      以下は週末の活動記録です。この人の休日の過ごし方を分析してください。

      活動記録:
      #{activities_text}

      以下の観点で分析し、日本語で回答してください：
      1. 主な活動パターン（カテゴリ別）
      2. 好きな場所や施設の傾向
      3. インドア・アウトドアの比率
      4. 文化的活動（美術館、展示会など）の頻度
      5. 旅行や遠出の傾向
      6. 「休日何してる？」という質問への簡潔な回答例

      回答は見やすい形式で、要点を整理してください。
    PROMPT

    payload = {
      contents: [{
        parts: [{
          text: prompt
        }]
      }]
    }

    uri = URI("#{@base_url}?key=#{@api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = payload.to_json

    response = http.request(request)

    if response.code == '200'
      result = JSON.parse(response.body)
      if result['candidates'] && !result['candidates'].empty?
        result['candidates'][0]['content']['parts'][0]['text']
      else
        '分析結果を取得できませんでした。'
      end
    else
      "API呼び出しエラー: #{response.code} #{response.message}"
    end
  rescue StandardError => e
    "エラーが発生しました: #{e.message}"
  end

  def generate_report(diary_path, output_path)
    puts '週末日記を読み込み中...'
    diary_content = read_weekend_diary(diary_path)

    return false if diary_content.empty?

    puts '活動データを抽出中...'
    activities = extract_activities(diary_content)

    if activities.empty?
      puts '活動データが見つかりませんでした'
      return false
    end

    puts "抽出された活動数: #{activities.length}"
    puts 'Gemini APIで分析中...'

    analysis = analyze_with_gemini(activities)

    active_days = activities.count { |a| !a['activity'].empty? }

    report_content = <<~REPORT
      # 週末活動分析レポート

      生成日時: #{Time.now.strftime('%Y年%m月%d日 %H:%M:%S')}

      ## 分析対象データ
      - 分析期間の活動数: #{activities.length}件
      - 記録されている活動がある日数: #{active_days}日

      ## AI分析結果

      #{analysis}

      ---
      *このレポートはGemini APIを使用して自動生成されました*
    REPORT

    File.write(output_path, report_content, encoding: 'utf-8')
    puts "レポートを生成しました: #{output_path}"
    true
  rescue StandardError => e
    puts "レポート書き込みエラー: #{e.message}"
    false
  end
end

def main
  api_key = ENV['GEMINI_API_KEY']
  if api_key.nil? || api_key.empty?
    puts 'Error: GEMINI_API_KEY環境変数が設定されていません'
    return
  end

  diary_path = 'diary/2025/weekend/weekend_diary.md'
  output_path = 'diary/2025/weekend/analysis_report.md'

  analyzer = WeekendAnalyzer.new(api_key)
  success = analyzer.generate_report(diary_path, output_path)

  if success
    puts '分析完了！'
  else
    puts '分析に失敗しました'
  end
end

main if __FILE__ == $PROGRAM_NAME
