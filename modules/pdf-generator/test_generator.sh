#!/bin/bash

# PDF Generator Test Suite
# Tests all features and backends

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test directory
TEST_DIR="/tmp/pdf_generator_test_$$"
mkdir -p "$TEST_DIR"

echo -e "${BLUE}PDF Generator Test Suite${NC}"
echo "========================="

# Function to run test
run_test() {
    local name="$1"
    local cmd="$2"
    
    echo -n "Testing $name... "
    
    if eval "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

# System check
echo -e "\n${BLUE}1. System Check${NC}"
python3 pdf_generator.py --check

# Single file conversion tests
echo -e "\n${BLUE}2. Single File Conversion${NC}"

# Test with each backend if available
for method in pandoc wkhtmltopdf python-pdfkit python-md2pdf python-pypandoc; do
    output_file="$TEST_DIR/test_${method}.pdf"
    run_test "$method backend" \
        "python3 pdf_generator.py sample.md '$output_file' --method $method"
done

# Auto-select backend
run_test "auto backend selection" \
    "python3 pdf_generator.py sample.md '$TEST_DIR/test_auto.pdf'"

# Different input formats
echo -e "\n${BLUE}3. Input Format Tests${NC}"

# Create test files
echo "# HTML Test" > "$TEST_DIR/test.html"
echo "Plain text test" > "$TEST_DIR/test.txt"

run_test "HTML input" \
    "python3 pdf_generator.py '$TEST_DIR/test.html' '$TEST_DIR/html_output.pdf'"

run_test "Text input" \
    "python3 pdf_generator.py '$TEST_DIR/test.txt' '$TEST_DIR/text_output.pdf'"

# Batch conversion
echo -e "\n${BLUE}4. Batch Conversion${NC}"

# Create test directory with multiple files
BATCH_DIR="$TEST_DIR/batch_input"
BATCH_OUT="$TEST_DIR/batch_output"
mkdir -p "$BATCH_DIR"

for i in 1 2 3; do
    cat > "$BATCH_DIR/doc${i}.md" << EOF
# Document $i
This is test document number $i.

## Content
- Item 1
- Item 2
- Item 3

\`\`\`python
print("Document $i")
\`\`\`
EOF
done

run_test "batch conversion" \
    "python3 pdf_generator.py '$BATCH_DIR' '$BATCH_OUT' --batch"

# Check output files
if [ -f "$BATCH_OUT/doc1.pdf" ] && [ -f "$BATCH_OUT/doc2.pdf" ] && [ -f "$BATCH_OUT/doc3.pdf" ]; then
    echo -e "Batch files created: ${GREEN}✓${NC}"
else
    echo -e "Batch files missing: ${RED}✗${NC}"
fi

# Configuration test
echo -e "\n${BLUE}5. Configuration Test${NC}"

# Create custom config
cat > "$TEST_DIR/custom_config.json" << EOF
{
  "output": {
    "paper_size": "a4",
    "margin": "2cm",
    "font_size": "12pt"
  },
  "processing": {
    "table_of_contents": true,
    "numbered_sections": true
  }
}
EOF

run_test "custom configuration" \
    "python3 pdf_generator.py sample.md '$TEST_DIR/custom_config.pdf' --config '$TEST_DIR/custom_config.json'"

# Performance test
echo -e "\n${BLUE}6. Performance Test${NC}"

# Create large document
cat > "$TEST_DIR/large.md" << EOF
# Large Document Test

$(for i in {1..100}; do
    echo "## Section $i"
    echo "This is paragraph $i with some content to test performance."
    echo '```python'
    echo "def function_$i():"
    echo "    return $i * 2"
    echo '```'
    echo ""
done)
EOF

start_time=$(date +%s)
if python3 pdf_generator.py "$TEST_DIR/large.md" "$TEST_DIR/large.pdf" 2>/dev/null; then
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    echo -e "Large document (100 sections): ${GREEN}✓${NC} (${duration}s)"
else
    echo -e "Large document failed: ${RED}✗${NC}"
fi

# Error handling test
echo -e "\n${BLUE}7. Error Handling${NC}"

run_test "non-existent file" \
    "! python3 pdf_generator.py '/tmp/does_not_exist.md' '$TEST_DIR/error.pdf' 2>/dev/null"

run_test "invalid method" \
    "! python3 pdf_generator.py sample.md '$TEST_DIR/invalid.pdf' --method invalid_method 2>/dev/null"

# Summary
echo -e "\n${BLUE}Test Summary${NC}"
echo "============="

# Count PDF files created
pdf_count=$(find "$TEST_DIR" -name "*.pdf" 2>/dev/null | wc -l)
echo -e "PDF files created: ${GREEN}$pdf_count${NC}"

# Check file sizes
total_size=$(du -sh "$TEST_DIR" 2>/dev/null | cut -f1)
echo -e "Total size: $total_size"

# List created files
echo -e "\nCreated files:"
find "$TEST_DIR" -name "*.pdf" -exec basename {} \; | sort | sed 's/^/  /'

# Cleanup option
echo -e "\n${YELLOW}Test files in: $TEST_DIR${NC}"
read -p "Remove test files? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$TEST_DIR"
    echo -e "${GREEN}Test files removed${NC}"
else
    echo "Test files kept for inspection"
fi

echo -e "\n${GREEN}Test suite complete!${NC}"