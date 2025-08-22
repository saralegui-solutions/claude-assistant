// config.json - PDF Generator Configuration
{
    "page_size": "A4",
    "margins": {
        "top": "2.5cm",
        "bottom": "2.5cm",
        "left": "3cm",
        "right": "2.5cm"
    },
    "encoding": "utf-8",
    "highlight_style": "pygments",
    "toc": false,
    "number_sections": false,
    "preserve_tabs": true,
    "standalone": true,
    "font_size": "11pt",
    "line_height": "1.6",
    "pdf_options": {
        "enable_smart_shrinking": true,
        "print_media_type": true,
        "image_quality": 95,
        "minimum_font_size": 8
    }
}

// test_generator.sh - Quick Test Script
#!/bin/bash
#
# Quick test script for PDF generator
# Usage: ./test_generator.sh

echo "PDF Generator Test Suite"
echo "========================"

# Check dependencies
echo -e "\n1. Checking dependencies..."
python3 pdf_generator.py --check

# Test single file conversion
echo -e "\n2. Testing single file conversion..."
python3 pdf_generator.py sample.md test_output.pdf --config config.json

# Test with custom CSS (if exists)
if [ -f "custom.css" ]; then
    echo -e "\n3. Testing with custom CSS..."
    python3 pdf_generator.py sample.md test_styled.pdf --css custom.css
fi

# Test batch conversion
echo -e "\n4. Testing batch conversion..."
mkdir -p test_markdown test_pdfs
cp sample.md test_markdown/test1.md
cp sample.md test_markdown/test2.md
python3 pdf_generator.py test_markdown test_pdfs --batch

# Check results
echo -e "\n5. Test Results:"
echo "----------------"
if [ -f "test_output.pdf" ]; then
    echo "✅ Single file conversion: SUCCESS"
    ls -lh test_output.pdf
else
    echo "❌ Single file conversion: FAILED"
fi

if [ -d "test_pdfs" ] && [ "$(ls -A test_pdfs)" ]; then
    echo "✅ Batch conversion: SUCCESS"
    ls -lh test_pdfs/
else
    echo "❌ Batch conversion: FAILED"
fi

echo -e "\nTest complete!"

// custom.css - Optional Custom Styling
/* Professional PDF Styling */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono&display=swap');

body {
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    font-size: 11pt;
    line-height: 1.6;
    color: #2c3e50;
    max-width: 210mm;
    margin: 0 auto;
    padding: 0;
}

h1, h2, h3, h4, h5, h6 {
    font-weight: 600;
    color: #1a202c;
    margin-top: 1.5em;
    margin-bottom: 0.5em;
    page-break-after: avoid;
}

h1 {
    font-size: 24pt;
    border-bottom: 2px solid #3498db;
    padding-bottom: 0.3em;
}

h2 {
    font-size: 18pt;
    border-bottom: 1px solid #ecf0f1;
    padding-bottom: 0.2em;
}

h3 {
    font-size: 14pt;
}

code {
    font-family: 'JetBrains Mono', 'Courier New', monospace;
    font-size: 9pt;
    background-color: #f8f9fa;
    padding: 0.2em 0.4em;
    border-radius: 3px;
    color: #e74c3c;
}

pre {
    font-family: 'JetBrains Mono', 'Courier New', monospace;
    font-size: 9pt;
    background-color: #2c3e50;
    color: #ecf0f1;
    padding: 1em;
    border-radius: 5px;
    overflow-x: auto;
    page-break-inside: avoid;
}

pre code {
    background-color: transparent;
    color: inherit;
    padding: 0;
}

blockquote {
    border-left: 4px solid #3498db;
    padding-left: 1em;
    margin-left: 0;
    color: #5a6c7d;
    font-style: italic;
}

table {
    width: 100%;
    border-collapse: collapse;
    margin: 1em 0;
    page-break-inside: avoid;
}

table th {
    background-color: #34495e;
    color: white;
    font-weight: 600;
    padding: 0.75em;
    text-align: left;
}

table td {
    padding: 0.75em;
    border-bottom: 1px solid #ecf0f1;
}

table tr:nth-child(even) {
    background-color: #f8f9fa;
}

a {
    color: #3498db;
    text-decoration: none;
}

a:hover {
    text-decoration: underline;
}

/* Print-specific styles */
@media print {
    body {
        font-size: 10pt;
    }
    
    h1 {
        page-break-before: always;
    }
    
    h1:first-of-type {
        page-break-before: avoid;
    }
    
    pre, table, blockquote {
        page-break-inside: avoid;
    }
    
    a {
        color: #2c3e50;
        text-decoration: none;
    }
    
    a[href^="http"]:after {
        content: " (" attr(href) ")";
        font-size: 8pt;
        color: #7f8c8d;
    }
}
