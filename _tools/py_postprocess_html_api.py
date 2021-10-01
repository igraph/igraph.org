#!/bin/env python
import os
import re
from pathlib import Path
import shutil
import glob
import tempfile
import argparse

## Convert HTML files created by PyDoctor, to files to be used as
## Jekyll inputs

header_pydoctor='''---
layout: pydoctor
title: python-igraph API reference
mainheader: python-igraph API reference
lead: List of all classes, functions and methods in python-igraph
vmenu: true
'''

header_epydoc='''---
layout: epydoc
title: python-igraph manual
mainheader: python-igraph manual
lead: For using igraph from Python
vmenu: true
'''


if __name__ == '__main__':

    pa = argparse.ArgumentParser()
    pa.add_argument('folder')
    pa.add_argument('latest')
    args = pa.parse_args()

    folder = Path(args.folder)
    latest = args.latest

    for version in os.listdir(folder):
        if version == 'stamp':
            continue

        print('Processing version: '+version)

        if version in ['0.8.1', '0.9.0']:
            docgenerator = 'epydoc'
            header = header_epydoc
        else:
            docgenerator = 'pydoctor'
            header = header_pydoctor

        inhtml = glob.glob(str(folder)+'/'+version+'/*.html')
        print(inhtml)

        for ihname in inhtml:
            hf = os.path.basename(ihname)
            print(f'Converting {hf}...')

            with tempfile.TemporaryFile(dir='/tmp', mode='w+t') as tmpfile:

                # YAML header
                tmpfile.write(header)
                tmpfile.write(f'langversion: {version}\n')
                if version == latest:
                    path = Path(ihname)
                    latest_path = list(path.parts)
                    latest_path[latest_path.index(version)] = 'latest'
                    latest_path = Path(*latest_path)
                    tmpfile.write(f'redirect_from:\n  - {latest_path}\n')
                tmpfile.write('---\n')

                # Begin raw
                tmpfile.write('{% raw %}\n')

                if docgenerator == "pydoctor":
                    with open(ihname, 'rt') as ih:
                        # Strip header
                        for line in ih:
                            if '<body' in line:
                                break
                        line = '<div'+line[line.find('<body'):]
                        line = line[:line.find('>')+1]
                        tmpfile.write(line+'\n')
                        # Copy until footer
                        for line in ih:
                            if '</body' in line:
                                break
                            # Remove navbar class, replace with pydoctor-navbar
                            if 'class="navbar navbar-default"' in line:
                                line = re.sub(
                                    'class="navbar navbar-default"',
                                    'class="pydoctor-navbar navbar-default"',
                                    line,
                                )
                            tmpfile.write(line)
                        line = '</div>'
                        tmpfile.write(line+'\n')

                else:
                    with open(ihname, 'rt') as ih:
                        # Strip header
                        for line in ih:
                            if '<body' in line:
                                break
                        line = '<div'+line[line.find('<body'):]
                        # TODO: check that 0 is the right number?
                        line = line[:line.find('>')+0]
                        tmpfile.write(line+'\n')
                        # Copy until footer
                        for line in ih:
                            if '</body' in line:
                                break

                            # Take out links to frames / no frames
                            if 'frames.html' in line:
                                line = re.sub(
                                    r'\[[^[]*frames.html[^[]*]',
                                    r'',
                                    line,
                                    )

                            # Repair a bug in epydoc
                            if '</div>' in line:
                                line = re.sub(
                                        r'^</div>(<a name=)',
                                        r'\1',
                                        line,
                                        )

                            if 'class="navbar"' in line:
                                # Remove link from navbar
                                line = re.sub(
                                    r'<a class="navbar" [^>]*_top[^>]*igraph\.org[^>]*>[^<]*<\/a>',
                                    r'',
                                    line,
                                )
                                line = re.sub(
                                    'class="navbar"',
                                    'class="epynavbar"',
                                    line,
                                )

                            tmpfile.write(line)
                        line = '</div>'
                        tmpfile.write(line+'\n')

                # End raw
                tmpfile.write('{% endraw %}\n')

                # Replace
                tmpfile.seek(0)
                with open(ihname, 'wt') as ih:
                    ih.write(tmpfile.read())

        print("done.")
