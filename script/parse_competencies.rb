#!/usr/bin/env ruby

require "json"

class CompetencyParser
  def initialize
    @competencies = []
    @current_category = nil
    @current_subcategory = nil
  end

  def parse(markdown_file_path)
    content = File.read(markdown_file_path, encoding: "UTF-8")
    lines = content.split("\n")

    i = 0
    while i < lines.length
      line = lines[i].strip

      # Parse categories (e.g., "***1. Creating a Goal or Task***" or "***1\. Creating a Goal or Task***")
      if line.match?(/^\*\*\*\d+\\?\.\s*(.+)\*\*\*$/)
        category_name = line.match(/^\*\*\*\d+\\?\.\s*(.+)\*\*\*$/)[1].strip
        @current_category = category_name
        @current_subcategory = nil
        i += 1
        next
      end

      # Parse subcategories (e.g., "**Relevance**")
      if line.match?(/^\*\*([^*\[\]]+)\*\*$/) &&
         !line.match?(/^\*\*Name:\*\*/) &&
         !line.match?(/^\*\*Description:\*\*/) &&
         !line.match?(/In Action, This Looks Like/) &&
         !line.match?(/\[.*\]\(.*\)/) # Don't treat markdown links as subcategories
        @current_subcategory = line.match(/^\*\*([^*\[\]]+)\*\*$/)[1].strip
        i += 1
        next
      end

      # Parse competency names (e.g., "**Name:** Some Name")
      if line.match?(/^\*\*Name:\*\*\s*(.+)$/)
        competency_name = line.match(/^\*\*Name:\*\*\s*(.+)$/)[1].strip

        # Skip blank lines after Name:
        i += 1
        while i < lines.length && lines[i].strip.empty?
          i += 1
        end

        # Skip blank lines before Description:
        while i < lines.length && lines[i].strip.empty?
          i += 1
        end

        # Skip the Description: line
        if i < lines.length && lines[i].strip.match?(/^\*\*Description:\*\*$/)
          i += 1
        end

        # Skip blank lines after Description:
        while i < lines.length && lines[i].strip.empty?
          i += 1
        end

        # Collect description lines until we hit links or next competency/category
        description_lines = []
        while i < lines.length
          current_line = lines[i].strip

          # Stop if we hit another competency name or category
          break if current_line.match?(/^\*\*Name:\*\*/) ||
                   current_line.match?(/^\*\*\*\d+\\?\.\s*(.+)\*\*\*$/) ||
                   (current_line.match?(/^\*\*([^*\[\]]+)\*\*$/) &&
                    !current_line.match?(/In Action, This Looks Like/) &&
                    !current_line.match?(/\[.*\]\(.*\)/)) # Don't stop on markdown links

          # Stop if we hit a link (markdown format) - don't include links in description
          break if current_line.include?("[") && current_line.include?("](")

          # Add non-empty lines to description
          description_lines << current_line unless current_line.empty?

          i += 1
        end

        # Collect links from the remaining lines
        file_url = nil
        preview_image_url = nil

        while i < lines.length
          current_line = lines[i].strip

          # Stop if we hit another competency name or category
          break if current_line.match?(/^\*\*Name:\*\*/) ||
                   current_line.match?(/^\*\*\*\d+\\?\.\s*(.+)\*\*\*$/) ||
                   (current_line.match?(/^\*\*([^*\[\]]+)\*\*$/) &&
                    !current_line.match?(/In Action, This Looks Like/) &&
                    !current_line.match?(/\[.*\]\(.*\)/)) # Don't stop on markdown links

          # Extract links from markdown format [text](url)
          if current_line.include?("[") && current_line.include?("](")
            # Find all markdown links in the line
            current_line.scan(/\[([^\]]+)\]\(([^)]+)\)/) do |filename, url|
              # Clean filename of markdown formatting
              clean_filename = filename.gsub(/\*+/, "").strip
              if clean_filename.match?(/\.mp4$/) || url.match?(/\.mp4/)
                file_url = url
              elsif clean_filename.match?(/\.(jpg|png)$/) || url.match?(/\.(jpg|png)/)
                preview_image_url = url
              end
            end
          end

          i += 1
        end


        # Clean up description
        description = description_lines.join("\n").strip

        # Remove **Description:** heading if it appears at the beginning
        description = description.gsub(/^\*\*Description:\*\*\s*/, "")

        # Replace smart quotes with regular quotes
        description = description
          .gsub('"', '"')  # Replace left double quote
          .gsub('"', '"')  # Replace right double quote
          .gsub("'", "'")  # Replace left single quote

        # Create competency object
        competency = {
          name: competency_name,
          description: description,
          file_url: file_url,
          preview_image_url: preview_image_url,
          category: @current_category,
          sub_category: @current_subcategory,
          transcript: nil # Will be added later if needed
        }

        # Remove nil transcript field
        competency.delete(:transcript) if competency[:transcript].nil?

        @competencies << competency

        # Don't increment i here since we're already at the next line
        next
      end

      i += 1
    end
  end

  def save_to_json(output_file_path)
    File.write(output_file_path, JSON.pretty_generate(@competencies), encoding: "UTF-8")
    puts "✅ Parsed #{@competencies.length} competencies and saved to #{output_file_path}"
  end

  def validate_against_schema(json_file_path, schema_file_path)
    require "json"
    require "json-schema"

    # Load the schema
    schema = JSON.parse(File.read(schema_file_path, encoding: "UTF-8"))

    # Load the data
    data = JSON.parse(File.read(json_file_path, encoding: "UTF-8"))

    # Validate
    begin
      JSON::Validator.validate!(schema, data)
      puts "✅ JSON data is valid according to the schema"
      true
    rescue JSON::Schema::ValidationError => e
      puts "❌ Validation failed: #{e.message}"
      false
    end
  end
end

# Main execution
if __FILE__ == $0
  if ARGV.length < 2
    puts "Usage: ruby parse_competencies.rb <markdown_file> <output_json_file>"
    puts "Example: ruby parse_competencies.rb design/competencies.md competencies.json"
    exit 1
  end

  markdown_file_path = ARGV[0]
  output_file_path = ARGV[1]

  unless File.exist?(markdown_file_path)
    puts "❌ Error: Markdown file '#{markdown_file_path}' does not exist"
    exit 1
  end

  parser = CompetencyParser.new
  parser.parse(markdown_file_path)
  parser.save_to_json(output_file_path)

  # Validate against schema if it exists
  schema_file_path = "db/schemas/competencies_schema.json"
  if File.exist?(schema_file_path)
    parser.validate_against_schema(output_file_path, schema_file_path)
  else
    puts "⚠️  No schema file found at #{schema_file_path}, skipping validation"
  end
end
