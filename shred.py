#!/usr/bin/python
import zipfile
import sys
import re

XML_FILE = 'word/document.xml'
KEYWORDS = ('require', 'should', 'must', 'need', 'shall', 'may', 'will',
            'recommend', 'option')

REPLACEMENTS = (
    [r'<\/w:p><\/w:tc>(?!<\/w:tr>)', ' | '],
    [r'<w:tab[^\/]*\/>', ' '],
    [r'<\/w:p>', '\n'],
    [r'pic:pic[^>]*>', ''],
    [r'<wp:posOffset>\d+?<\/wp:posOffset>', ''],
    [r'<[^>]*>', ''],
    [r'&lt;', '<'],
    [r'&lt;', '<'],
    [r'&amp;', '&'],
    [r'&quot;', '"'],
    [r'&apos;', '\''],
)

REPLACE_RE = re.compile('.*(%s)' % '|'.join(KEYWORDS), re.IGNORECASE)

for filename in sys.argv[1:]:
    if not filename.endswith('.docx'):
        print '%s only supports .docx files' % (sys.argv[0])
        continue
    with zipfile.ZipFile(filename, 'r') as z:
        if XML_FILE not in z.namelist():
            print "%s not found in %s" % (XML_FILE, filename)
            continue
        data = z.read(XML_FILE)

        for m in REPLACEMENTS:
            data = re.sub(m[0], m[1], data)

        sentences = re.split(r'[.?!\n]', data)
        for sentence in sentences:
            m = REPLACE_RE.match(sentence)
            if m:
                print "requirement (%s) : %s" % (m.group(1), sentence.strip())
