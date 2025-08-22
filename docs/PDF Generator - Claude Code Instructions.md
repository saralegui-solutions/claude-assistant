# PDF Generator Setup Instructions for Claude Code

## Overview
This document provides instructions for setting up and using a PDF generation system that works completely offline with markdown files and other text sources.

## Prerequisites Installation

### Option 1: Recommended Setup (Pandoc + wkhtmltopdf)

#### On macOS:
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install pandoc and wkhtmltopdf
brew install pandoc
brew install --cask wkhtmltopdf
```

#### On Ubuntu/Debian:
```bash
# Update package list
sudo apt update

# Install pandoc
sudo apt install pandoc

# Install wkhtmltopdf
sudo apt install wkhtmltopdf
```

#### On Windows:
1. Download and install Pandoc from: https://pandoc.org/installing.html
2. Download and install wkhtmltopdf from: https://wkhtmltopdf.org/downloads.html
3. Add both to your system PATH

### Option 2: Python Fallback Setup
```bash
# Install Python packages for fallback PDF generation
pip install markdown2 pdfkit md2pdf pypandoc beautifulsoup4
```

## Usage Instructions

### Basic Commands

#### 1. Simple Markdown to PDF:
```bash
# Using the main script
python pdf_generator.py input.md output.pdf

# Direct pandoc command
pandoc input.md -o output.pdf --pdf-engine=wkhtmltopdf
```

#### 2. With Custom Styling:
```bash
# Using custom CSS
python pdf_generator.py input.md output.pdf --css custom.css

# With pandoc directly
pandoc input.md -o output.pdf --pdf-engine=wkhtmltopdf --css=custom.css
```

#### 3. Batch Processing:
```bash
# Convert all markdown files in a directory
python pdf_generator.py --batch ./markdown_files/ ./pdf_output/
```

#### 4. Multiple Input Formats:
```bash
# Convert various formats
python pdf_generator.py input.txt output.pdf
python pdf_generator.py input.html output.pdf
python pdf_generator.py input.rst output.pdf
```

## Features

### Supported Input Formats:
- Markdown (.md, .markdown)
- Plain text (.txt)
- HTML (.html, .htm)
- reStructuredText (.rst)
- JSON (formatted as code blocks)
- Source code files (with syntax highlighting)

### Conversion Options:
- Custom CSS styling
- Page size configuration (A4, Letter, Legal, etc.)
- Margin settings
- Header/footer templates
- Table of contents generation
- Syntax highlighting for code blocks
- Image embedding (local images only)

### Error Handling:
- Automatic fallback to Python methods if pandoc/wkhtmltopdf unavailable
- Validation of input files
- Safe handling of special characters
- UTF-8 encoding support

## Project Structure

```
pdf_generator/
├── pdf_generator.py       # Main conversion script
├── config.json            # Configuration settings
├── templates/
│   ├── default.css       # Default styling
│   ├── header.html       # Header template
│   └── footer.html       # Footer template
├── test_files/
│   ├── sample.md         # Sample markdown
│   └── test_output/      # Test outputs
└── README.md             # This file
```

## Troubleshooting

### Common Issues:

1. **"pandoc: command not found"**
   - Ensure pandoc is installed and in PATH
   - Script will automatically fall back to Python methods

2. **"wkhtmltopdf: cannot connect to X server"** (Linux)
   - Install xvfb: `sudo apt install xvfb`
   - Use with: `xvfb-run python pdf_generator.py input.md output.pdf`

3. **Images not showing in PDF**
   - Ensure image paths are absolute or relative to the markdown file
   - Check that images are in supported formats (PNG, JPG, GIF)

4. **UTF-8 encoding issues**
   - Files are automatically handled as UTF-8
   - For other encodings, use `--encoding` flag

### Performance Tips:

1. For large batches, use `--parallel` flag for concurrent processing
2. Cache CSS and templates to avoid repeated disk reads
3. Use `--optimize` flag to reduce PDF file size

## Advanced Usage

### Custom Templates:
Create a custom HTML template with placeholders:
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>{css_content}</style>
</head>
<body>
    {body_content}
</body>
</html>
```

### Programmatic Usage:
```python
from pdf_generator import PDFGenerator

# Initialize generator
gen = PDFGenerator()

# Convert single file
gen.convert('input.md', 'output.pdf', css='custom.css')

# Batch convert
gen.batch_convert('./markdown/', './pdfs/')
```

## Testing

Run the test suite:
```bash
python test_pdf_generator.py
```

This will:
- Test all conversion methods
- Verify fallback mechanisms
- Check output quality
- Validate error handling

## Notes for Claude Code

When using this in Claude Code:
1. Always check for tool availability first
2. Use the Python script for maximum compatibility
3. Provide clear error messages to users
4. Offer to install missing dependencies
5. Test with the sample markdown file first
