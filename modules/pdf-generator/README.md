# PDF Generator Module for Claude Assistant

Professional PDF generation with multiple backend support and automatic fallback.

## Features

- 🚀 **Multiple Backends**: Pandoc, wkhtmltopdf, Python libraries
- 🔄 **Automatic Fallback**: Always produces a PDF using best available method
- 📁 **Batch Processing**: Convert entire directories
- 🎨 **Custom Styling**: Professional CSS templates
- 📝 **Format Support**: Markdown, HTML, Text, reStructuredText
- ⚡ **Offline Operation**: No internet required after setup

## Quick Start

```bash
# Check available methods
python pdf_generator.py --check

# Convert single file
python pdf_generator.py input.md output.pdf

# Batch convert directory
python pdf_generator.py ./docs/ ./pdfs/ --batch

# Use specific method
python pdf_generator.py input.md output.pdf --method pandoc
```

## Installation

### Automatic (via Claude Assistant installer)
```bash
# From main claude-assistant directory
./install.sh
# Select [4] pdf-generator or [A] All modules
```

### Manual Installation

#### macOS
```bash
# Install system tools
brew install pandoc
brew install --cask wkhtmltopdf

# Install Python packages
pip install markdown2 pdfkit md2pdf pypandoc weasyprint
```

#### Linux (Ubuntu/Debian)
```bash
# Install system tools
sudo apt update
sudo apt install pandoc wkhtmltopdf texlive-latex-base

# Install Python packages
pip install markdown2 pdfkit md2pdf pypandoc weasyprint
```

#### Windows (WSL)
```bash
# Same as Linux instructions above
```

## Usage Examples

### Basic Conversion
```python
from pdf_generator import PDFGenerator

# Initialize generator
gen = PDFGenerator()

# Convert single file
gen.convert('README.md', 'documentation.pdf')

# Batch convert
success, total = gen.batch_convert('./docs/', './pdfs/')
print(f"Converted {success}/{total} files")
```

### Command Line
```bash
# Check system status
python pdf_generator.py --check

# Simple conversion
python pdf_generator.py README.md readme.pdf

# With custom config
python pdf_generator.py input.md output.pdf --config custom.json

# Batch with pattern
python pdf_generator.py ./src/ ./docs/ --batch --pattern "*.md"

# Force specific backend
python pdf_generator.py input.md output.pdf --method wkhtmltopdf

# Verbose output
python pdf_generator.py input.md output.pdf --verbose
```

### Integration with Claude Code
```python
#!/usr/bin/env python3
"""Export Claude conversation to PDF"""

import sys
from pathlib import Path
from pdf_generator import PDFGenerator

def export_conversation(conversation_file):
    """Export Claude conversation to PDF"""
    generator = PDFGenerator()
    
    output_file = Path(conversation_file).with_suffix('.pdf')
    
    if generator.convert(conversation_file, str(output_file)):
        print(f"✓ Exported to: {output_file}")
    else:
        print(f"✗ Failed to export: {conversation_file}")
        sys.exit(1)

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: export_conversation.py <conversation.md>")
        sys.exit(1)
    
    export_conversation(sys.argv[1])
```

## Configuration

### config.json
```json
{
  "output": {
    "paper_size": "letter",    // letter, a4, legal
    "margin": "1in",           // CSS margin format
    "font_size": "11pt",       // CSS font size
    "font_family": "Arial",    // Font family
    "orientation": "portrait"  // portrait or landscape
  },
  "processing": {
    "syntax_highlighting": true,  // Enable code highlighting
    "table_of_contents": false,   // Generate TOC
    "numbered_sections": false,   // Number sections
    "preserve_tabs": true         // Preserve tab characters
  },
  "paths": {
    "custom_css": "custom.css",  // Path to CSS file
    "output_dir": "."            // Default output directory
  }
}
```

### Custom CSS
Edit `custom.css` to customize PDF appearance:
- Typography and fonts
- Colors and highlighting
- Page layout and margins
- Special element styling

## Backend Methods

### Priority Order
1. **pandoc** - Best quality, LaTeX support
2. **wkhtmltopdf** - Good HTML rendering
3. **python-pdfkit** - Pure Python with wkhtmltopdf
4. **python-md2pdf** - Simple markdown to PDF
5. **python-pypandoc** - Python pandoc wrapper
6. **python-weasyprint** - CSS-focused rendering

### Method Comparison

| Method | Quality | Speed | Dependencies | Features |
|--------|---------|-------|--------------|----------|
| pandoc | ⭐⭐⭐⭐⭐ | Fast | pandoc, LaTeX | Full LaTeX, math support |
| wkhtmltopdf | ⭐⭐⭐⭐ | Fast | wkhtmltopdf | Good HTML/CSS |
| python-pdfkit | ⭐⭐⭐⭐ | Medium | pdfkit, wkhtmltopdf | Python integration |
| python-md2pdf | ⭐⭐⭐ | Fast | md2pdf | Simple, lightweight |
| python-pypandoc | ⭐⭐⭐⭐⭐ | Fast | pypandoc, pandoc | Python pandoc wrapper |
| python-weasyprint | ⭐⭐⭐⭐ | Slow | weasyprint | Advanced CSS |

## Troubleshooting

### No Methods Available
```bash
# Install at least one backend
pip install markdown2 pdfkit md2pdf

# Or install system tools
brew install pandoc  # macOS
sudo apt install pandoc  # Linux
```

### Pandoc LaTeX Errors
```bash
# Install LaTeX (for pandoc PDF generation)
# macOS
brew install --cask mactex-no-gui

# Linux
sudo apt install texlive-latex-base texlive-fonts-recommended
```

### wkhtmltopdf Issues
```bash
# Check installation
which wkhtmltopdf

# Test directly
echo "<h1>Test</h1>" | wkhtmltopdf - test.pdf
```

### Python Module Errors
```bash
# Reinstall dependencies
pip install --upgrade markdown2 pdfkit md2pdf pypandoc

# For pdfkit, ensure wkhtmltopdf is in PATH
export PATH="/usr/local/bin:$PATH"
```

### Permission Errors
```bash
# Make script executable
chmod +x pdf_generator.py

# Check write permissions
touch test.pdf && rm test.pdf
```

## Advanced Usage

### Custom Backend Implementation
```python
class PDFGenerator:
    def convert_with_custom(self, input_file, output_file):
        """Add your custom conversion method"""
        try:
            # Your implementation here
            pass
        except Exception as e:
            logger.error(f"Custom conversion failed: {e}")
            return False
```

### Preprocessing Markdown
```python
def preprocess_markdown(content):
    """Preprocess markdown before conversion"""
    # Add custom headers
    content = f"# Generated on {datetime.now()}\n\n" + content
    
    # Replace custom tags
    content = content.replace('[[TOC]]', '[Table of Contents]')
    
    return content
```

### Post-processing PDFs
```bash
# Compress PDF
gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 \
   -dPDFSETTINGS=/screen -dNOPAUSE -dQUIET \
   -dBATCH -sOutputFile=compressed.pdf input.pdf

# Merge multiple PDFs
gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite \
   -sOutputFile=merged.pdf file1.pdf file2.pdf
```

## Integration with Claude Assistant

### Automatic PDF Export Hook
```bash
#!/bin/bash
# ~/.claude/hooks/export-to-pdf.sh

CONVERSATION_DIR="$HOME/.claude/conversations"
PDF_DIR="$HOME/.claude/pdfs"

# Create PDF directory
mkdir -p "$PDF_DIR"

# Find today's conversations
find "$CONVERSATION_DIR" -name "*.md" -mtime 0 | while read -r file; do
    filename=$(basename "$file" .md)
    python ~/.claude/pdf_generator.py "$file" "$PDF_DIR/${filename}.pdf"
done
```

### Dashboard PDF Report
```bash
# Generate dashboard report as PDF
claude-assistant dashboard --export | \
    python pdf_generator.py - dashboard_report.pdf
```

## Files

- `pdf_generator.py` - Main generator script
- `config.json` - Default configuration
- `custom.css` - Professional styling
- `sample.md` - Test document
- `install.sh` - Installation script
- `test_generator.sh` - Test suite

## Support

- Issues: [Claude Assistant GitHub](https://github.com/anthropics/claude-code/issues)
- Documentation: See main Claude Assistant docs
- Module version: 1.0.0

---

*Part of Claude Assistant Suite - Professional PDF Generation for Claude Code*