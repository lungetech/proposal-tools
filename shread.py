#!/usr/bin/env python
import zipfile
import sys
import re

xml_file = 'word/document.xml'
keywords = ('require', 'should', 'must', 'need', 'shall', 'may', 'will', 'recommend', 'option')

matches = (
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

my_re = re.compile('.*(%s)' % '|'.join(keywords), re.IGNORECASE)

requirements = []
for filename in sys.argv[1:]:
    if not filename.endswith('.docx'):
        print('%s only supports .docx files' % (sys.argv[0]))
        continue
    with zipfile.ZipFile(filename, 'r') as z:
        if xml_file not in z.namelist():
            print("Error processing file (%s).  no word/document.xml found" % filename)
            continue
        data = z.read(xml_file)

        for m in matches:
            data = re.sub(m[0], m[1], data)

        sentences = re.split(r'[.?!\n]', data)
        for sentence in sentences:
            m = my_re.match(sentence)
            if m:
                print("requirement (%s) : %s" % (m.group(1), sentence.strip()))
