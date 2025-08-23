# PDF Generator Module

## Overview
Professional PDF generation with multiple backend support, automatic fallback, and custom styling capabilities.

## Features
- 🔄 Multiple backend support (6 methods)
- 🎯 Automatic fallback if one method fails
- 📁 Batch conversion for directories
- 🎨 Custom CSS styling
- 📝 Support for MD, HTML, TXT, RST
- ⚡ Works completely offline

## Installation

### Via Interactive Installer
```bash
./install-interactive.sh
# Select: [4] PDF Generator
```

### Manual Installation
```bash
./modules/pdf-generator/install.sh
```

## Usage

### Basic Commands
```bash
# Single file conversion
pdf input.md output.pdf
claude-pdf input.md output.pdf
ca pdf input.md output.pdf

# Check system capabilities
pdf --check

# Batch conversion
pdf ./docs/ ./pdfs/ --batch

# With specific method
pdf input.md output.pdf --method pandoc
```

### Quick Aliases
```bash
pdf                     # Direct PDF generator
ca-pdf                  # Via Claude assistant
ca-docs                 # Convert all .md in current dir
```

## Conversion Methods

### Priority Order
1. **pandoc** - Highest quality, LaTeX support
2. **wkhtmltopdf** - Good HTML/CSS rendering
3. **python-pdfkit** - Python with wkhtmltopdf
4. **python-md2pdf** - Pure Python, simple
5. **python-pypandoc** - Python pandoc wrapper
6. **python-weasyprint** - Advanced CSS support

### Method Comparison
| Method | Quality | Speed | Math Support | CSS Support |
|--------|---------|-------|--------------|-------------|
| pandoc | ⭐⭐⭐⭐⭐ | Fast | Full LaTeX | Basic |
| wkhtmltopdf | ⭐⭐⭐⭐ | Fast | No | Full |
| pdfkit | ⭐⭐⭐⭐ | Medium | No | Full |
| md2pdf | ⭐⭐⭐ | Fast | No | Basic |
| pypandoc | ⭐⭐⭐⭐⭐ | Fast | Full LaTeX | Basic |
| weasyprint | ⭐⭐⭐⭐ | Slow | No | Advanced |

## Configuration

### File Location
`~/.claude/pdf-generator/config.json`

### Configuration Options
```json
{
  "output": {
    "paper_size": "letter",      // letter, a4, legal
    "margin": "1in",             // CSS format
    "font_size": "11pt",
    "font_family": "Arial, sans-serif",
    "orientation": "portrait"    // portrait, landscape
  },
  "processing": {
    "syntax_highlighting": true,
    "table_of_contents": false,
    "numbered_sections": false,
    "preserve_tabs": true
  },
  "paths": {
    "custom_css": "custom.css",
    "output_dir": ".",
    "temp_dir": "/tmp"
  }
}
```

## Custom Styling

### CSS Location
`~/.claude/pdf-generator/custom.css`

### CSS Examples
```css
/* Custom header style */
h1 {
    color: #2c3e50;
    border-bottom: 3px solid #3498db;
    padding-bottom: 10px;
}

/* Code block styling */
pre {
    background: #f8f9fa;
    border-left: 4px solid #0366d6;
    padding: 12px;
}

/* Page breaks */
.page-break {
    page-break-after: always;
}
```

## Batch Processing

### Convert Directory
```bash
# All markdown files
pdf ./docs/ ./output/ --batch

# Specific pattern
pdf ./docs/ ./output/ --batch --pattern "*.md"

# Recursive
find . -name "*.md" -exec pdf {} {}.pdf \;
```

### Automated Workflows
```bash
#!/bin/bash
# Convert all project documentation

for dir in modules/*/; do
    module=$(basename "$dir")
    pdf "$dir/README.md" "docs/pdf/${module}.pdf"
done
```

## Dependencies

### Required (at least one)
- **System**: pandoc OR wkhtmltopdf
- **Python**: markdown2 + (pdfkit OR md2pdf OR pypandoc)

### Optional (for best results)
- **pandoc**: Full featured conversion
- **LaTeX**: For pandoc PDF generation
- **wkhtmltopdf**: HTML to PDF conversion
- **All Python packages**: Maximum compatibility

### Installation Commands

#### macOS
```bash
brew install pandoc
brew install --cask wkhtmltopdf
brew install --cask mactex-no-gui  # LaTeX
pip install markdown2 pdfkit md2pdf pypandoc weasyprint
```

#### Linux/WSL
```bash
sudo apt install pandoc wkhtmltopdf
sudo apt install texlive-latex-base  # LaTeX
pip install markdown2 pdfkit md2pdf pypandoc weasyprint
```

## Troubleshooting

### No Methods Available
```bash
# Check what's missing
pdf --check

# Install minimal requirements
pip install markdown2 pdfkit
```

### Pandoc Errors
```bash
# Check pandoc version
pandoc --version

# Install LaTeX for pandoc
sudo apt install texlive-latex-base texlive-fonts-recommended
```

### wkhtmltopdf Issues
```bash
# Verify installation
which wkhtmltopdf
wkhtmltopdf --version

# Test directly
echo "<h1>Test</h1>" | wkhtmltopdf - test.pdf
```

### Python Import Errors
```bash
# Reinstall packages
pip install --upgrade --force-reinstall markdown2 pdfkit

# Check Python path
python3 -c "import sys; print(sys.path)"
```

## Advanced Usage

### Custom Headers/Footers
```python
# In config.json
{
  "output": {
    "header": "Document Title",
    "footer": "Page [page] of [topage]"
  }
}
```

### Watermarks
```css
/* In custom.css */
body::before {
    content: "DRAFT";
    position: fixed;
    top: 50%;
    left: 50%;
    font-size: 100px;
    color: rgba(0,0,0,0.1);
    transform: rotate(-45deg);
    z-index: -1;
}
```

### Table of Contents
```bash
# Enable in config
pdf input.md output.pdf --toc

# Or in config.json
"table_of_contents": true
```

## Integration Examples

### With Claude Conversations
```bash
# Export latest conversation
latest=$(ls -t ~/.claude/conversations/*.md | head -1)
pdf "$latest" "conversation_$(date +%Y%m%d).pdf"
```

### With Git Hooks
```bash
#!/bin/bash
# .git/hooks/pre-commit
# Generate PDF of README before commit

pdf README.md docs/README.pdf
git add docs/README.pdf
```

### CI/CD Pipeline
```yaml
# .github/workflows/docs.yml
- name: Generate PDFs
  run: |
    ./claude-assistant/modules/pdf-generator/install.sh
    claude-pdf README.md README.pdf
    claude-pdf --batch ./docs/ ./docs/pdf/
```

## Performance Tips
1. Use pandoc for large documents
2. wkhtmltopdf for HTML-heavy content
3. Batch process during off-hours
4. Cache converted files
5. Use --method to skip detection

## Files Installed
- `~/.claude/bin/claude-pdf` - Main wrapper
- `~/.claude/pdf-generator/pdf_generator.py` - Core script
- `~/.claude/pdf-generator/config.json` - Configuration
- `~/.claude/pdf-generator/custom.css` - Styling
- `~/.claude/pdf-generator/sample.md` - Test document

## Version
Current: 2.0
Python: 3.6+
Compatible with: All platforms