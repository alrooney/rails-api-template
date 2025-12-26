# Utility Scripts

This directory contains utility scripts for processing competency data.

## Scripts

### `parse_competencies.rb`
Parses the competencies markdown file and generates a structured JSON file.

**Usage:**
```bash
ruby script/parse_competencies.rb design/competencies.md db/competencies.json
```

**Features:**
- Extracts competency names, descriptions, categories, and subcategories
- Handles markdown formatting and links
- Generates JSON schema-compliant output
- Replaces smart quotes with regular quotes

### `transcribe_competencies.rb`
Downloads video files and generates transcripts using the local `transcribe` utility.

**Usage:**
```bash
# Process all competencies
ruby script/transcribe_competencies.rb db/competencies.json

# Test mode (process only first competency)
ruby script/transcribe_competencies.rb db/competencies.json --test

# Batch mode (process first 10 competencies)
ruby script/transcribe_competencies.rb db/competencies.json --batch-10
```

**Features:**
- Downloads videos from Google Drive with virus scan bypass
- Caches downloaded videos in `tmp/competency_videos/` to avoid re-downloading
- Generates transcripts using Whisper via the `transcribe` utility
- Tracks and reports failed downloads
- Updates the JSON file with transcript data
- Cleans up temporary audio files while preserving videos

**Requirements:**
- Local `transcribe` utility installed and accessible
- Internet connection for video downloads
- Sufficient disk space for video caching

### `db/seeds/competencies.rb`
Seeds competencies from `db/competencies.json` into the database with file attachments.

**Usage:**
```bash
# Run as part of db:seed
bin/rails db:seed

# Or run individually
bin/rails runner "load Rails.root.join('db', 'seeds', 'competencies.rb')"
```

**Features:**
- Downloads and attaches video files and preview images from Google Drive URLs
- Uses cached files from `tmp/competency_videos/` if already downloaded
- Creates competency categories and subcategories automatically
- Handles Google Drive virus scan bypass for large files
- Associates competencies with appropriate categories
- **Error Handling**: Tracks download failures separately from database errors
- **Skip Logic**: Skips competencies with missing video files (balanced approach)
- **Detailed Reporting**: Provides comprehensive failure summary with URLs and error messages

## Directory Structure

```
script/
├── README.md                    # This file
├── parse_competencies.rb        # Markdown to JSON parser
└── transcribe_competencies.rb   # Video download and transcription

db/seeds/
└── competencies.rb              # Database seeding with file attachments
```

## Output Directories

- `tmp/competency_videos/` - Cached video files (shared between scripts)
- `tmp/competency_transcripts/` - Temporary transcript files (cleaned up after processing)
