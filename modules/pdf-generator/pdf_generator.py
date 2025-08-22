#!/usr/bin/env python3
"""
PDF Generator for Claude Code
Multi-backend PDF generation with automatic fallback
Supports: Markdown, HTML, Text, reStructuredText
"""

import os
import sys
import json
import logging
import argparse
import subprocess
from pathlib import Path
from typing import Optional, Dict, List, Tuple

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class PDFGenerator:
    """Multi-backend PDF generator with automatic fallback"""
    
    def __init__(self, config_file: Optional[str] = None):
        self.config = self.load_config(config_file)
        self.available_methods = self.detect_available_methods()
        
    def load_config(self, config_file: Optional[str]) -> Dict:
        """Load configuration from JSON file or use defaults"""
        default_config = {
            "output": {
                "paper_size": "letter",
                "margin": "1in",
                "font_size": "11pt",
                "font_family": "Arial, sans-serif",
                "orientation": "portrait"
            },
            "processing": {
                "syntax_highlighting": True,
                "table_of_contents": False,
                "numbered_sections": False,
                "preserve_tabs": True
            },
            "paths": {
                "custom_css": "custom.css",
                "output_dir": "."
            }
        }
        
        if config_file and Path(config_file).exists():
            try:
                with open(config_file, 'r') as f:
                    user_config = json.load(f)
                # Merge configurations
                for key in user_config:
                    if key in default_config:
                        default_config[key].update(user_config[key])
                    else:
                        default_config[key] = user_config[key]
            except Exception as e:
                logger.warning(f"Could not load config file: {e}")
        
        return default_config
    
    def detect_available_methods(self) -> List[str]:
        """Detect which PDF generation methods are available"""
        methods = []
        
        # Check for pandoc
        if self.check_command('pandoc'):
            methods.append('pandoc')
            logger.info("✓ Pandoc detected")
        
        # Check for wkhtmltopdf
        if self.check_command('wkhtmltopdf'):
            methods.append('wkhtmltopdf')
            logger.info("✓ wkhtmltopdf detected")
        
        # Check for Python libraries
        try:
            import markdown2
            import pdfkit
            methods.append('python-pdfkit')
            logger.info("✓ Python pdfkit detected")
        except ImportError:
            pass
        
        try:
            import md2pdf
            methods.append('python-md2pdf')
            logger.info("✓ Python md2pdf detected")
        except ImportError:
            pass
        
        try:
            import pypandoc
            methods.append('python-pypandoc')
            logger.info("✓ Python pypandoc detected")
        except ImportError:
            pass
        
        try:
            import weasyprint
            methods.append('python-weasyprint')
            logger.info("✓ Python weasyprint detected")
        except ImportError:
            pass
        
        if not methods:
            logger.warning("⚠ No PDF generation methods available!")
            logger.info("Install one of: pandoc, wkhtmltopdf, or pip install pdfkit md2pdf pypandoc")
        
        return methods
    
    def check_command(self, command: str) -> bool:
        """Check if a command is available in PATH"""
        try:
            subprocess.run(
                ['which', command],
                capture_output=True,
                check=True
            )
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            return False
    
    def convert(self, input_file: str, output_file: str, 
                method: Optional[str] = None) -> bool:
        """Convert input file to PDF using specified or best available method"""
        
        input_path = Path(input_file)
        if not input_path.exists():
            logger.error(f"Input file not found: {input_file}")
            return False
        
        # Determine file type
        file_ext = input_path.suffix.lower()
        
        # Select method
        if method and method in self.available_methods:
            methods_to_try = [method]
        else:
            methods_to_try = self.available_methods
        
        if not methods_to_try:
            logger.error("No PDF generation methods available")
            return False
        
        # Try each method until one succeeds
        for current_method in methods_to_try:
            logger.info(f"Attempting conversion with: {current_method}")
            
            try:
                if current_method == 'pandoc':
                    return self.convert_with_pandoc(input_file, output_file)
                elif current_method == 'wkhtmltopdf':
                    return self.convert_with_wkhtmltopdf(input_file, output_file)
                elif current_method == 'python-pdfkit':
                    return self.convert_with_pdfkit(input_file, output_file)
                elif current_method == 'python-md2pdf':
                    return self.convert_with_md2pdf(input_file, output_file)
                elif current_method == 'python-pypandoc':
                    return self.convert_with_pypandoc(input_file, output_file)
                elif current_method == 'python-weasyprint':
                    return self.convert_with_weasyprint(input_file, output_file)
            except Exception as e:
                logger.warning(f"Method {current_method} failed: {e}")
                continue
        
        logger.error("All conversion methods failed")
        return False
    
    def convert_with_pandoc(self, input_file: str, output_file: str) -> bool:
        """Convert using pandoc"""
        try:
            cmd = [
                'pandoc',
                input_file,
                '-o', output_file,
                '--pdf-engine=pdflatex',
                f'--variable=geometry:{self.config["output"]["margin"]}',
                f'--variable=fontsize:{self.config["output"]["font_size"]}',
            ]
            
            if self.config['processing']['syntax_highlighting']:
                cmd.append('--highlight-style=tango')
            
            if self.config['processing']['table_of_contents']:
                cmd.append('--toc')
            
            if self.config['processing']['numbered_sections']:
                cmd.append('--number-sections')
            
            subprocess.run(cmd, check=True, capture_output=True)
            logger.info(f"✓ Successfully created: {output_file}")
            return True
            
        except subprocess.CalledProcessError as e:
            logger.error(f"Pandoc conversion failed: {e.stderr.decode() if e.stderr else str(e)}")
            return False
    
    def convert_with_wkhtmltopdf(self, input_file: str, output_file: str) -> bool:
        """Convert using wkhtmltopdf"""
        try:
            # First convert markdown to HTML if needed
            input_path = Path(input_file)
            
            if input_path.suffix.lower() in ['.md', '.markdown']:
                html_content = self.markdown_to_html(input_file)
                temp_html = input_path.with_suffix('.html')
                temp_html.write_text(html_content)
                input_file = str(temp_html)
            
            cmd = [
                'wkhtmltopdf',
                '--page-size', self.config['output']['paper_size'].capitalize(),
                '--margin-top', self.config['output']['margin'],
                '--margin-bottom', self.config['output']['margin'],
                '--margin-left', self.config['output']['margin'],
                '--margin-right', self.config['output']['margin'],
                '--encoding', 'utf-8',
                input_file,
                output_file
            ]
            
            subprocess.run(cmd, check=True, capture_output=True)
            
            # Clean up temp file
            if 'temp_html' in locals():
                temp_html.unlink()
            
            logger.info(f"✓ Successfully created: {output_file}")
            return True
            
        except Exception as e:
            logger.error(f"wkhtmltopdf conversion failed: {e}")
            return False
    
    def convert_with_pdfkit(self, input_file: str, output_file: str) -> bool:
        """Convert using Python pdfkit"""
        try:
            import pdfkit
            import markdown2
            
            # Read input file
            with open(input_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Convert markdown to HTML if needed
            if Path(input_file).suffix.lower() in ['.md', '.markdown']:
                html = markdown2.markdown(
                    content,
                    extras=['fenced-code-blocks', 'tables', 'code-friendly']
                )
            else:
                html = content
            
            # Add CSS styling
            styled_html = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <style>
                    body {{
                        font-family: {self.config['output']['font_family']};
                        font-size: {self.config['output']['font_size']};
                        line-height: 1.6;
                        max-width: 900px;
                        margin: 0 auto;
                        padding: 20px;
                    }}
                    code {{
                        background: #f4f4f4;
                        padding: 2px 5px;
                        border-radius: 3px;
                    }}
                    pre {{
                        background: #f4f4f4;
                        padding: 10px;
                        border-radius: 5px;
                        overflow-x: auto;
                    }}
                    table {{
                        border-collapse: collapse;
                        width: 100%;
                    }}
                    th, td {{
                        border: 1px solid #ddd;
                        padding: 8px;
                        text-align: left;
                    }}
                    th {{
                        background-color: #f2f2f2;
                    }}
                </style>
            </head>
            <body>
                {html}
            </body>
            </html>
            """
            
            # Convert to PDF
            options = {
                'page-size': self.config['output']['paper_size'].capitalize(),
                'margin-top': self.config['output']['margin'],
                'margin-right': self.config['output']['margin'],
                'margin-bottom': self.config['output']['margin'],
                'margin-left': self.config['output']['margin'],
                'encoding': 'UTF-8',
                'no-outline': None
            }
            
            pdfkit.from_string(styled_html, output_file, options=options)
            logger.info(f"✓ Successfully created: {output_file}")
            return True
            
        except Exception as e:
            logger.error(f"pdfkit conversion failed: {e}")
            return False
    
    def convert_with_md2pdf(self, input_file: str, output_file: str) -> bool:
        """Convert using Python md2pdf"""
        try:
            from md2pdf.core import md2pdf
            
            md2pdf(
                output_file,
                md_file_path=input_file,
                css_file_path=self.config['paths'].get('custom_css'),
                base_url=os.path.dirname(os.path.abspath(input_file))
            )
            
            logger.info(f"✓ Successfully created: {output_file}")
            return True
            
        except Exception as e:
            logger.error(f"md2pdf conversion failed: {e}")
            return False
    
    def convert_with_pypandoc(self, input_file: str, output_file: str) -> bool:
        """Convert using Python pypandoc"""
        try:
            import pypandoc
            
            extra_args = [
                f'--variable=geometry:{self.config["output"]["margin"]}',
                f'--variable=fontsize:{self.config["output"]["font_size"]}',
            ]
            
            if self.config['processing']['syntax_highlighting']:
                extra_args.append('--highlight-style=tango')
            
            pypandoc.convert_file(
                input_file,
                'pdf',
                outputfile=output_file,
                extra_args=extra_args
            )
            
            logger.info(f"✓ Successfully created: {output_file}")
            return True
            
        except Exception as e:
            logger.error(f"pypandoc conversion failed: {e}")
            return False
    
    def convert_with_weasyprint(self, input_file: str, output_file: str) -> bool:
        """Convert using Python weasyprint"""
        try:
            from weasyprint import HTML, CSS
            import markdown2
            
            # Read and convert markdown
            with open(input_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            if Path(input_file).suffix.lower() in ['.md', '.markdown']:
                html_content = markdown2.markdown(
                    content,
                    extras=['fenced-code-blocks', 'tables']
                )
            else:
                html_content = content
            
            # Create full HTML
            html = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <style>
                    @page {{
                        size: {self.config['output']['paper_size']};
                        margin: {self.config['output']['margin']};
                    }}
                    body {{
                        font-family: {self.config['output']['font_family']};
                        font-size: {self.config['output']['font_size']};
                    }}
                </style>
            </head>
            <body>{html_content}</body>
            </html>
            """
            
            HTML(string=html).write_pdf(output_file)
            logger.info(f"✓ Successfully created: {output_file}")
            return True
            
        except Exception as e:
            logger.error(f"weasyprint conversion failed: {e}")
            return False
    
    def markdown_to_html(self, input_file: str) -> str:
        """Convert markdown to HTML"""
        try:
            import markdown2
            with open(input_file, 'r', encoding='utf-8') as f:
                content = f.read()
            return markdown2.markdown(
                content,
                extras=['fenced-code-blocks', 'tables', 'code-friendly']
            )
        except ImportError:
            # Fallback to basic conversion
            with open(input_file, 'r', encoding='utf-8') as f:
                return f"<pre>{f.read()}</pre>"
    
    def batch_convert(self, input_dir: str, output_dir: str, 
                     pattern: str = "*.md") -> Tuple[int, int]:
        """Convert all matching files in a directory"""
        input_path = Path(input_dir)
        output_path = Path(output_dir)
        
        if not input_path.exists():
            logger.error(f"Input directory not found: {input_dir}")
            return 0, 0
        
        output_path.mkdir(parents=True, exist_ok=True)
        
        files = list(input_path.glob(pattern))
        success_count = 0
        
        for file in files:
            output_file = output_path / file.with_suffix('.pdf').name
            logger.info(f"Converting: {file.name}")
            
            if self.convert(str(file), str(output_file)):
                success_count += 1
        
        return success_count, len(files)
    
    def check_system(self) -> Dict:
        """Check system capabilities and return status"""
        status = {
            'available_methods': self.available_methods,
            'pandoc': self.check_command('pandoc'),
            'wkhtmltopdf': self.check_command('wkhtmltopdf'),
            'pdflatex': self.check_command('pdflatex'),
            'python_modules': {}
        }
        
        # Check Python modules
        modules = ['markdown2', 'pdfkit', 'md2pdf', 'pypandoc', 'weasyprint']
        for module in modules:
            try:
                __import__(module)
                status['python_modules'][module] = True
            except ImportError:
                status['python_modules'][module] = False
        
        return status

def main():
    """Command-line interface"""
    parser = argparse.ArgumentParser(
        description='Convert documents to PDF with multiple backend support'
    )
    parser.add_argument(
        'input',
        nargs='?',
        help='Input file or directory'
    )
    parser.add_argument(
        'output',
        nargs='?',
        help='Output PDF file or directory'
    )
    parser.add_argument(
        '--config',
        help='Configuration JSON file',
        default='config.json'
    )
    parser.add_argument(
        '--method',
        choices=['pandoc', 'wkhtmltopdf', 'python-pdfkit', 
                'python-md2pdf', 'python-pypandoc', 'python-weasyprint'],
        help='Force specific conversion method'
    )
    parser.add_argument(
        '--batch',
        action='store_true',
        help='Batch convert directory'
    )
    parser.add_argument(
        '--pattern',
        default='*.md',
        help='File pattern for batch conversion (default: *.md)'
    )
    parser.add_argument(
        '--check',
        action='store_true',
        help='Check system capabilities'
    )
    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Enable verbose output'
    )
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Initialize generator
    generator = PDFGenerator(args.config)
    
    # Check system
    if args.check:
        status = generator.check_system()
        print("\n=== PDF Generator System Check ===\n")
        print(f"Available methods: {', '.join(status['available_methods']) or 'None'}")
        print(f"\nSystem commands:")
        print(f"  pandoc:      {'✓ Installed' if status['pandoc'] else '✗ Not found'}")
        print(f"  wkhtmltopdf: {'✓ Installed' if status['wkhtmltopdf'] else '✗ Not found'}")
        print(f"  pdflatex:    {'✓ Installed' if status['pdflatex'] else '✗ Not found'}")
        print(f"\nPython modules:")
        for module, installed in status['python_modules'].items():
            print(f"  {module:12} {'✓ Installed' if installed else '✗ Not found'}")
        
        if not status['available_methods']:
            print("\n⚠ WARNING: No PDF generation methods available!")
            print("\nInstall at least one of the following:")
            print("  - pandoc: brew install pandoc (macOS) or apt install pandoc (Linux)")
            print("  - wkhtmltopdf: brew install --cask wkhtmltopdf (macOS) or apt install wkhtmltopdf (Linux)")
            print("  - Python modules: pip install markdown2 pdfkit md2pdf pypandoc")
        else:
            print(f"\n✓ System ready for PDF generation")
        
        return 0
    
    # Require input/output for conversion
    if not args.input or not args.output:
        parser.print_help()
        return 1
    
    # Perform conversion
    if args.batch:
        success, total = generator.batch_convert(
            args.input,
            args.output,
            args.pattern
        )
        print(f"\nBatch conversion complete: {success}/{total} files converted")
        return 0 if success == total else 1
    else:
        success = generator.convert(args.input, args.output, args.method)
        return 0 if success else 1

if __name__ == '__main__':
    sys.exit(main())