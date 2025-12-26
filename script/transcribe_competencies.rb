#!/usr/bin/env ruby

require "json"
require "net/http"
require "uri"
require "fileutils"

class CompetencyTranscriber
  def initialize(json_file_path, test_mode = false)
    @json_file_path = json_file_path
    @competencies = JSON.parse(File.read(json_file_path, encoding: "UTF-8"))
    @downloads_dir = "tmp/competency_videos"
    @transcripts_dir = "tmp/competency_transcripts"
    @test_mode = test_mode
    @failed_downloads = []

    # Create directories if they don't exist
    FileUtils.mkdir_p(@downloads_dir)
    FileUtils.mkdir_p(@transcripts_dir)
  end

  def transcribe_all
    if @test_mode == true
      puts "🧪 TEST MODE: Processing only the first competency..."
      competencies_to_process = @competencies.first(1)
    elsif @test_mode == :batch_10
      puts "🧪 BATCH MODE: Processing first 10 competencies..."
      competencies_to_process = @competencies.first(10)
    else
      puts "🎬 Starting transcription of #{@competencies.length} competencies..."
      competencies_to_process = @competencies
    end

    competencies_to_process.each_with_index do |competency, index|
      puts "\n📹 Processing #{index + 1}/#{competencies_to_process.length}: #{competency['name']}"

      # Skip if transcript already exists
      if competency["transcript"] && !competency["transcript"].empty?
        puts "  ⏭️  Transcript already exists, skipping"
        next
      end

      # Skip if no file_url
      unless competency["file_url"]
        puts "  ⚠️  No file URL, skipping"
        next
      end

      begin
        transcript = transcribe_competency(competency)
        if transcript
          competency["transcript"] = transcript
          puts "  ✅ Transcript added successfully"
        else
          puts "  ❌ Failed to generate transcript"
          @failed_downloads << competency["name"]
        end
      rescue => e
        puts "  ❌ Error processing competency: #{e.message}"
        @failed_downloads << competency["name"]
      end
    end

    # Save updated JSON
    save_updated_json
    puts "\n🎉 Transcription process completed!"

    # Print summary of failed downloads
    if @failed_downloads.any?
      puts "\n❌ Failed Downloads Summary:"
      puts "=" * 50
      @failed_downloads.each_with_index do |name, index|
        puts "#{index + 1}. #{name}"
      end
      puts "=" * 50
      puts "Total failed: #{@failed_downloads.length}"
      puts "\n💡 Check the URLs for these competencies - they may be broken or inaccessible."
    else
      puts "\n✅ All downloads completed successfully!"
    end
  end

  private

  def transcribe_competency(competency)
    file_url = competency["file_url"]
    competency_name = competency["name"]

    # Generate safe filename from competency name
    safe_filename = competency_name.downcase
      .gsub(/[^a-z0-9\s]/, "")  # Remove special characters
      .gsub(/\s+/, "_")         # Replace spaces with underscores
      .gsub(/_+/, "_")          # Replace multiple underscores with single
      .gsub(/^_|_$/, "")        # Remove leading/trailing underscores

    # Download the video file
    video_path = download_video(file_url, safe_filename)
    return nil unless video_path

    # Transcribe using local transcribe utility
    transcript_path = transcribe_video(video_path)
    return nil unless transcript_path

    # Read the transcript
    transcript = File.read(transcript_path, encoding: "UTF-8").strip

    # Clean up downloaded files
    cleanup_files(video_path, transcript_path)

    transcript
  end

  def download_video(url, filename)
    video_path = File.join(@downloads_dir, "#{filename}.mp4")

    # Check if video already exists
    if File.exist?(video_path)
      puts "  📁 Video already exists, skipping download"
      puts "  📊 File size: #{File.size(video_path)} bytes"
      return video_path
    end

    puts "  📥 Downloading video..."
    puts "  🔗 Original URL: #{url}"

    # Convert Google Drive share URL to direct download URL
    direct_url = convert_google_drive_url(url)
    puts "  🔗 Direct URL: #{direct_url}"

    begin
      uri = URI(direct_url)

      # Handle redirects by following them
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        request = Net::HTTP::Get.new(uri)
        response = http.request(request)

        # Follow redirects
        while response.is_a?(Net::HTTPRedirection)
          puts "  🔄 Following redirect to: #{response['location']}"
          redirect_uri = URI(response["location"])
          request = Net::HTTP::Get.new(redirect_uri)
          response = http.request(request)
        end

        if response.code == "200"
          # Check if we got a virus scan warning page
          if response.body.include?("Google Drive can't scan this file for viruses")
            puts "  ⚠️  Virus scan warning detected, attempting bypass..."

            # Extract the UUID from the form
            uuid_match = response.body.match(/name="uuid" value="([^"]+)"/)
            if uuid_match
              uuid = uuid_match[1]
              file_id = url.match(/\/file\/d\/([a-zA-Z0-9_-]+)\//)[1]
              bypass_url = "https://drive.usercontent.google.com/download?id=#{file_id}&export=download&confirm=t&uuid=#{uuid}"

              puts "  🔄 Attempting bypass URL: #{bypass_url}"
              bypass_uri = URI(bypass_url)
              bypass_request = Net::HTTP::Get.new(bypass_uri)
              bypass_response = http.request(bypass_request)

              if bypass_response.code == "200"
                video_path = File.join(@downloads_dir, "#{filename}.mp4")
                File.write(video_path, bypass_response.body, mode: "wb")
                puts "  ✅ Downloaded to #{video_path}"
                puts "  📊 File size: #{File.size(video_path)} bytes"
                video_path
              else
                puts "  ❌ Bypass failed: HTTP #{bypass_response.code}"
                nil
              end
            else
              puts "  ❌ Could not extract UUID from virus scan warning"
              nil
            end
          else
            video_path = File.join(@downloads_dir, "#{filename}.mp4")
            File.write(video_path, response.body, mode: "wb")
            puts "  ✅ Downloaded to #{video_path}"
            puts "  📊 File size: #{File.size(video_path)} bytes"
            video_path
          end
        else
          puts "  ❌ Failed to download: HTTP #{response.code}"
          puts "  📄 Response body: #{response.body[0..200]}..." if response.body
          nil
        end
      end
    rescue => e
      puts "  ❌ Download error: #{e.message}"
      nil
    end
  end

  def convert_google_drive_url(share_url)
    # Extract file ID from Google Drive share URL
    # Format: https://drive.google.com/file/d/FILE_ID/view?usp=sharing
    if share_url.match(/\/file\/d\/([a-zA-Z0-9_-]+)\//)
      file_id = share_url.match(/\/file\/d\/([a-zA-Z0-9_-]+)\//)[1]
      "https://drive.google.com/uc?export=download&id=#{file_id}"
    else
      share_url
    end
  end

  def transcribe_video(video_path)
    puts "  🎤 Transcribing video..."

    # Generate transcript filename
    transcript_path = video_path.gsub(".mp4", ".txt")

    begin
      # Run the transcribe utility
      # Using --formats txt to only generate text transcript
      cmd = "transcribe --formats txt --lang en \"#{video_path}\""
      puts "  🔧 Running: #{cmd}"

      success = system(cmd)

      if success
        puts "  ✅ Transcribe command completed successfully"
      else
        puts "  ❌ Transcribe command failed"
        return nil
      end

      # Check if transcript was created
      if File.exist?(transcript_path)
        puts "  ✅ Transcript created at #{transcript_path}"
        transcript_path
      else
        puts "  ❌ Transcript file not found"
        nil
      end
    rescue => e
      puts "  ❌ Transcription error: #{e.message}"
      nil
    end
  end

  def cleanup_files(video_path, transcript_path)
    puts "  🧹 Cleaning up temporary files..."

    # Keep the downloaded video file for future use
    # Only remove transcript file (we've already read it)
    File.delete(transcript_path) if File.exist?(transcript_path)

    # Remove any .wav files created by transcribe
    wav_path = video_path.gsub(".mp4", ".wav")
    File.delete(wav_path) if File.exist?(wav_path)

    puts "  ✅ Cleanup completed"
  end

  def save_updated_json
    puts "\n💾 Saving updated JSON file..."
    File.write(@json_file_path, JSON.pretty_generate(@competencies), encoding: "UTF-8")
    puts "✅ JSON file updated successfully"
  end
end

# Main execution
if __FILE__ == $0
  if ARGV.length < 1
    puts "Usage: ruby transcribe_competencies.rb <json_file> [--test|--batch-10]"
    puts "Example: ruby transcribe_competencies.rb competencies.json --test"
    puts "Example: ruby transcribe_competencies.rb competencies.json --batch-10"
    exit 1
  end

  json_file_path = ARGV[0]
  test_mode = ARGV.include?("--test") ? true : (ARGV.include?("--batch-10") ? :batch_10 : false)

  unless File.exist?(json_file_path)
    puts "❌ Error: JSON file '#{json_file_path}' does not exist"
    exit 1
  end

  transcriber = CompetencyTranscriber.new(json_file_path, test_mode)
  transcriber.transcribe_all
end
