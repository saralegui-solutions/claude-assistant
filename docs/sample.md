# Sample Markdown Document for PDF Testing

## Introduction

This is a comprehensive test document designed to verify all features of the PDF generator. It includes various markdown elements to ensure proper conversion.

## Text Formatting

This paragraph demonstrates **bold text**, *italic text*, ***bold italic text***, and `inline code`. You can also use ~~strikethrough~~ text.

> This is a blockquote. It's useful for highlighting important information or quotes from other sources.
> 
> Blockquotes can span multiple paragraphs.

## Lists

### Unordered List
- First item
- Second item
  - Nested item 1
  - Nested item 2
    - Deep nested item
- Third item

### Ordered List
1. First step
2. Second step
   1. Sub-step A
   2. Sub-step B
3. Third step

### Task List
- [x] Completed task
- [ ] Pending task
- [x] Another completed task
- [ ] Future task

## Code Blocks

### Python Example
```python
def generate_pdf(input_file, output_file):
    """
    Convert markdown to PDF with syntax highlighting
    """
    with open(input_file, 'r') as f:
        content = f.read()
    
    # Process the content
    processed = process_markdown(content)
    
    # Generate PDF
    create_pdf(processed, output_file)
    print(f"PDF created: {output_file}")
```

### JavaScript Example
```javascript
// Function to handle PDF generation
async function convertToPDF(markdown) {
    const html = marked.parse(markdown);
    const options = {
        format: 'A4',
        margin: { top: '2cm', bottom: '2cm' }
    };
    
    const pdf = await generatePDF(html, options);
    return pdf;
}
```

### Bash Example
```bash
#!/bin/bash
# Convert all markdown files in directory

for file in *.md; do
    output="${file%.md}.pdf"
    pandoc "$file" -o "$output" --pdf-engine=wkhtmltopdf
    echo "Converted: $file -> $output"
done
```

## Tables

### Simple Table
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Data 1   | Data 2   | Data 3   |
| Data 4   | Data 5   | Data 6   |
| Data 7   | Data 8   | Data 9   |

### Aligned Table
| Left Aligned | Center Aligned | Right Aligned |
|:-------------|:--------------:|--------------:|
| Left         | Center         | Right         |
| Text         | Text           | Text          |
| More         | More           | More          |

### Complex Table
| Feature | Description | Status | Priority |
|---------|-------------|--------|----------|
| Markdown Support | Full CommonMark compliance | ✅ Complete | High |
| PDF Generation | Multiple backend support | ✅ Complete | High |
| Syntax Highlighting | Code block highlighting | ✅ Complete | Medium |
| Custom Styling | CSS support | ✅ Complete | Medium |
| Batch Processing | Multiple file conversion | ✅ Complete | Low |
| Image Support | Local image embedding | 🔄 In Progress | Medium |

## Links and References

Here's an [inline link](https://example.com) and a [reference link][ref1].

You can also use direct URLs: https://github.com

[ref1]: https://example.com "Reference Link Title"

## Horizontal Rules

Text above the line.

---

Text below the line.

***

Another separator.

## Mathematical Expressions

Inline math: $E = mc^2$

Block math:
$$
\frac{n!}{k!(n-k)!} = \binom{n}{k}
$$

## Special Characters and Escaping

Special characters: & < > " ' © ® ™ € £ ¥

Escaped characters: \* \_ \# \+ \- \. \! \[ \] \( \)

## Footnotes

Here's a sentence with a footnote[^1].

Here's another one[^2].

[^1]: This is the first footnote.
[^2]: This is the second footnote with more content.

## Definition Lists

Term 1
:   Definition for term 1

Term 2
:   Definition for term 2
:   Another definition for term 2

## HTML Elements

<details>
<summary>Click to expand</summary>

This content is hidden by default and can be expanded.
- Item 1
- Item 2
- Item 3

</details>

## Emoji Support

Here are some emojis: 😀 🚀 💻 📚 ✅ ⚡ 🎨

## Long Form Content

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.

## Nested Structures

1. **Main Point One**
   - Supporting detail A
     - Evidence 1
     - Evidence 2
   - Supporting detail B
     > Important quote about this point
     
2. **Main Point Two**
   ```
   Code example for this point
   ```
   - Additional information
   
3. **Main Point Three**
   
   | Sub-topic | Details |
   |-----------|---------|
   | Topic A   | Info A  |
   | Topic B   | Info B  |

## Conclusion

This document has demonstrated various markdown features including:

1. ✅ Text formatting
2. ✅ Lists (ordered, unordered, task)
3. ✅ Code blocks with syntax highlighting
4. ✅ Tables with alignment
5. ✅ Links and references
6. ✅ Mathematical expressions
7. ✅ Special characters
8. ✅ And much more!

The PDF generator should handle all these elements correctly, producing a well-formatted PDF document suitable for professional use.

---

*Generated by PDF Generator Tool v1.0*
