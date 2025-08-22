#!/usr/bin/env python3
"""
PDF Generator - Offline PDF creation from Markdown and other formats
Supports multiple conversion methods with automatic fallback
"""

import os
import sys
import json
import shutil
import tempfile
import argparse
import subprocess
from pathlib import Path
from typing import Optional, List, Dict, Any
import logging

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class PDFGenerator:
    """Main PDF generation class with multiple backend support"""
    
    def __init__(self, config_path: Optional[str] = None):
        """Initialize PDF generator with configuration"""
        self.config = self.load_config(config_path)
        self.available_tools = self.check_available_tools()
        self.temp_dir = tempfile.mkdtemp(prefix='pdf_gen_')
        
    def load_config(self, config_path: Optional[str] = None) -> Dict[str, Any]:
        """Load configuration from JSON file or use defaults"""
        default_config = {
            "page_size": "A4",
            "margins": {
                "top": "2cm",
                "bottom": "2cm",
                "left": "2cm",
                "right": "2cm"
            },
            "encoding": "utf-8",
            "highlight_style": "pygments",
            "toc": False,
            "number_sections": False,
            "preserve_tabs": True,
            "standalone": True
        }
        
        if config_path and Path(config_path).exists():
            try:
                with open(config_path, 'r') as f:
                    user_config = json.load(f)
                    default_config.update(user_config)
            except Exception as e:
                logger.warning(f"Could not load config file: {e}. Using defaults.")
        
        return default_config
    
    def check_available_tools(self) -> Dict[str, bool]:
        """Check which PDF generation tools are available"""
        tools = {
            'pandoc': False,
            'wkhtmltopdf': False,
            'pdfkit': False,
            'md2pdf': False,
            'weasyprint': False
        }
        
        # Check for pandoc
        if shutil.which('pandoc'):
            tools['pandoc'] = True
            logger.info("✓ Pandoc found")
        else:
            logger.warning("✗ Pandoc not found")
        
        # Check for wkhtmltopdf
        if shutil.which('wkhtmltopdf'):
            tools['wkhtmltopdf'] = True
            logger.info("✓ wkhtmltopdf found")
        else:
            logger.warning("✗ wkhtmltopdf not found")
        
        # Check for Python packages
        try:
            import pdfkit
            tools['pdfkit'] = True
            logger.info("✓ pdfkit (Python) found")
        except ImportError:
            logger.warning("✗ pdfkit not installed")
        
        try:
            import md2pdf
            tools['md2pdf'] = True
            logger.info("✓ md2pdf (Python) found")
        except ImportError:
            logger.warning("✗ md2pdf not installed")
        
        try:
            import weasyprint
            tools['weasyprint'] = True
            logger.info("✓ WeasyPrint found")
        except ImportError:
            logger.warning("✗ WeasyPrint not installed")
        
        return tools
    
    def convert(self, input_file: str, output_file: str, 
                css_file: Optional[str] = None, 
                method: Optional[str] = None) -> bool:
        """
        Convert input file to PDF using available methods
        
        Args:
            input_file: Path to input file
            output_file: Path to output PDF
            css_file: Optional CSS file for styling
            method: Force specific conversion method
        
        Returns:
            True if successful, False otherwise
        """
        input_path = Path(input_file)
        output_path = Path(output_file)
        
        if not input_path.exists():
            logger.error(f"Input file not found: {input_file}")
            return False
        
        # Ensure output directory exists
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Determine conversion method
        if method:
            if method == 'pandoc' and self.available_tools['pandoc']:
                return self._convert_with_pandoc(input_path, output_path, css_file)
            elif method == 'python':
                return self._convert_with_python(input_path, output_path, css_file)
            else:
                logger.error(f"Method {method} not available")
                return False
        
        # Try methods in order of preference
        if self.available_tools['pandoc']:
            if self._convert_with_pandoc(input_path, output_path, css_file):
                return True
            logger.warning("Pandoc conversion failed, trying Python fallback...")
        
        return self._convert_with_python(input_path, output_path, css_file)
    
    def _convert_with_pandoc(self, input_path: Path, output_path: Path, 
                            css_file: Optional[str] = None) -> bool:
        """Convert using pandoc with wkhtmltopdf or fallback"""
        try:
            cmd = ['pandoc', str(input_path), '-o', str(output_path)]
            
            # Add configuration options
            if self.config['standalone']:
                cmd.append('--standalone')
            
            if self.config['toc']:
                cmd.append('--toc')
            
            if self.config['number_sections']:
                cmd.append('--number-sections')
            
            # Set highlight style for code blocks
            cmd.extend(['--highlight-style', self.config['highlight_style']])
            
            # Add CSS if provided
            if css_file and Path(css_file).exists():
                cmd.extend(['--css', css_file])
            else:
                # Use default CSS
                default_css = self._get_default_css()
                css_temp = Path(self.temp_dir) / 'default.css'
                css_temp.write_text(default_css)
                cmd.extend(['--css', str(css_temp)])
            
            # Try with wkhtmltopdf if available
            if self.available_tools['wkhtmltopdf']:
                cmd.extend(['--pdf-engine', 'wkhtmltopdf'])
                
                # Add wkhtmltopdf specific options
                pdf_options = [
                    f"--margin-top={self.config['margins']['top']}",
                    f"--margin-bottom={self.config['margins']['bottom']}",
                    f"--margin-left={self.config['margins']['left']}",
                    f"--margin-right={self.config['margins']['right']}",
                    f"--page-size={self.config['page_size']}"
                ]
                
                for opt in pdf_options:
                    cmd.extend(['--pdf-engine-opt', opt])
            
            # Execute conversion
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                logger.info(f"✓ PDF created successfully: {output_path}")
                return True
            else:
                logger.error(f"Pandoc error: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Pandoc conversion failed: {e}")
            return False
    
    def _convert_with_python(self, input_path: Path, output_path: Path,
                            css_file: Optional[str] = None) -> bool:
        """Convert using Python libraries as fallback"""
        try:
            # First, try md2pdf if available
            if self.available_tools['md2pdf'] and input_path.suffix in ['.md', '.markdown']:
                try:
                    from md2pdf.core import md2pdf
                    
                    with open(input_path, 'r', encoding='utf-8') as f:
                        md_content = f.read()
                    
                    md2pdf(str(output_path),
                          md_content=md_content,
                          css_file_path=css_file or None,
                          base_url=str(input_path.parent))
                    
                    logger.info(f"✓ PDF created with md2pdf: {output_path}")
                    return True
                except Exception as e:
                    logger.warning(f"md2pdf failed: {e}")
            
            # Try pdfkit with wkhtmltopdf
            if self.available_tools['pdfkit'] and self.available_tools['wkhtmltopdf']:
                try:
                    import pdfkit
                    import markdown
                    
                    # Read input file
                    with open(input_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Convert markdown to HTML if needed
                    if input_path.suffix in ['.md', '.markdown']:
                        html_content = markdown.markdown(content, 
                                                        extensions=['extra', 'codehilite', 'toc'])
                    else:
                        html_content = content
                    
                    # Wrap with HTML template
                    css_content = self._get_css_content(css_file)
                    full_html = f"""
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <meta charset="utf-8">
                        <style>{css_content}</style>
                    </head>
                    <body>
                        {html_content}
                    </body>
                    </html>
                    """
                    
                    # PDF options
                    options = {
                        'page-size': self.config['page_size'],
                        'margin-top': self.config['margins']['top'],
                        'margin-right': self.config['margins']['right'],
                        'margin-bottom': self.config['margins']['bottom'],
                        'margin-left': self.config['margins']['left'],
                        'encoding': "UTF-8",
                        'enable-local-file-access': None
                    }
                    
                    pdfkit.from_string(full_html, str(output_path), options=options)
                    logger.info(f"✓ PDF created with pdfkit: {output_path}")
                    return True
                    
                except Exception as e:
                    logger.warning(f"pdfkit failed: {e}")
            
            # Try WeasyPrint as last resort
            if self.available_tools['weasyprint']:
                try:
                    from weasyprint import HTML, CSS
                    import markdown
                    
                    with open(input_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    if input_path.suffix in ['.md', '.markdown']:
                        html_content = markdown.markdown(content,
                                                        extensions=['extra', 'codehilite', 'toc'])
                    else:
                        html_content = content
                    
                    css_content = self._get_css_content(css_file)
                    full_html = f"""
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <meta charset="utf-8">
                        <style>{css_content}</style>
                    </head>
                    <body>
                        {html_content}
                    </body>
                    </html>
                    """
                    
                    HTML(string=full_html).write_pdf(str(output_path))
                    logger.info(f"✓ PDF created with WeasyPrint: {output_path}")
                    return True
                    
                except Exception as e:
                    logger.warning(f"WeasyPrint failed: {e}")
            
            logger.error("All Python conversion methods failed")
            return False
            
        except Exception as e:
            logger.error(f"Python conversion failed: {e}")
            return False
    
    def _get_default_css(self) -> str:
        """Return default CSS styling"""
        return """
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 900px;
            margin: 0 auto;
            padding: 20px;
        }
        
        h1, h2, h3, h4, h5, h6 {
            margin-top: 24px;
            margin-bottom: 16px;
            font-weight: 600;
            line-height: 1.25;
        }
        
        h1 { font-size: 2em; border-bottom: 1px solid #eaecef; padding-bottom: 0.3em; }
        h2 { font-size: 1.5em; border-bottom: 1px solid #eaecef; padding-bottom: 0.3em; }
        h3 { font-size: 1.25em; }
        
        code {
            background-color: #f6f8fa;
            padding: 0.2em 0.4em;
            border-radius: 3px;
            font-size: 85%;
        }
        
        pre {
            background-color: #f6f8fa;
            padding: 16px;
            overflow: auto;
            border-radius: 6px;
            line-height: 1.45;
        }
        
        pre code {
            background-color: transparent;
            padding: 0;
        }
        
        blockquote {
            padding: 0 1em;
            color: #6a737d;
            border-left: 0.25em solid #dfe2e5;
            margin: 0;
        }
        
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 16px 0;
        }
        
        table th, table td {
            padding: 6px 13px;
            border: 1px solid #dfe2e5;
        }
        
        table tr:nth-child(2n) {
            background-color: #f6f8fa;
        }
        
        img {
            max-width: 100%;
            height: auto;
        }
        
        a {
            color: #0366d6;
            text-decoration: none;
        }
        
        a:hover {
            text-decoration: underline;
        }
        
        ul, ol {
            padding-left: 2em;
        }
        
        li {
            margin: 0.25em 0;
        }
        
        @media print {
            body {
                max-width: 100%;
            }
            pre {
                white-space: pre-wrap;
                word-wrap: break-word;
            }
        }
        """
    
    def _get_css_content(self, css_file: Optional[str] = None) -> str:
        """Get CSS content from file or default"""
        if css_file and Path(css_file).exists():
            with open(css_file, 'r', encoding='utf-8') as f:
                return f.read()
        return self._get_default_css()
    
    def batch_convert(self, input_dir: str, output_dir: str,
                     pattern: str = "*.md") -> List[bool]:
        """Convert multiple files matching pattern"""
        input_path = Path(input_dir)
        output_path = Path(output_dir)
        
        if not input_path.exists():
            logger.error(f"Input directory not found: {input_dir}")
            return []
        
        output_path.mkdir(parents=True, exist_ok=True)
        
        files = list(input_path.glob(pattern))
        results = []
        
        logger.info(f"Found {len(files)} files to convert")
        
        for i, file in enumerate(files, 1):
            logger.info(f"Converting {i}/{len(files)}: {file.name}")
            output_file = output_path / f"{file.stem}.pdf"
            success = self.convert(str(file), str(output_file))
            results.append(success)
        
        successful = sum(results)
        logger.info(f"Batch conversion complete: {successful}/{len(files)} successful")
        
        return results
    
    def cleanup(self):
        """Clean up temporary files"""
        try:
            shutil.rmtree(self.temp_dir)
        except Exception as e:
            logger.warning(f"Could not clean up temp directory: {e}")


def main():
    """Command-line interface"""
    parser = argparse.ArgumentParser(description='Convert Markdown and other formats to PDF')
    parser.add_argument('input', help='Input file or directory for batch mode')
    parser.add_argument('output', help='Output PDF file or directory for batch mode')
    parser.add_argument('--css', help='Custom CSS file for styling')
    parser.add_argument('--config', help='Configuration JSON file')
    parser.add_argument('--method', choices=['pandoc', 'python'], help='Force specific method')
    parser.add_argument('--batch', action='store_true', help='Batch convert directory')
    parser.add_argument('--pattern', default='*.md', help='File pattern for batch mode')
    parser.add_argument('--check', action='store_true', help='Check available tools and exit')
    
    args = parser.parse_args()
    
    # Initialize generator
    generator = PDFGenerator(config_path=args.config)
    
    # Check tools only
    if args.check:
        print("\nAvailable PDF Generation Tools:")
        print("-" * 30)
        for tool, available in generator.available_tools.items():
            status = "✓" if available else "✗"
            print(f"{status} {tool}")
        sys.exit(0)
    
    # Batch conversion
    if args.batch:
        results = generator.batch_convert(args.input, args.output, args.pattern)
        generator.cleanup()
        sys.exit(0 if all(results) else 1)
    
    # Single file conversion
    success = generator.convert(args.input, args.output, css_file=args.css, method=args.method)
    generator.cleanup()
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
