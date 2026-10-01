from pathlib import Path

from paperless.parsers.text import TextDocumentParser

source = Path('/tmp/thumbnail_font.txt')
source.write_text('syncloud thumbnail font check')
with TextDocumentParser() as parser:
    thumbnail = parser.get_thumbnail(source, 'text/plain')
    print('thumbnail bytes', thumbnail.stat().st_size)
