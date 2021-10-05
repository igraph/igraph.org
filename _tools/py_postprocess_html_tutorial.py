#!/usr/bin/env python3
import os
import re
from pathlib import Path
import shutil
import glob
import tempfile
import argparse

## Add version metadata


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

        inhtml = glob.glob(str(folder)+'/'+version+'/*.html')

        for ihname in inhtml:
            hf = os.path.basename(ihname)
            print(f'Converting {hf}...')

            with tempfile.TemporaryFile(dir='/tmp', mode='w+t') as tmpfile:

                # Add metadata at the end of YAML header
                with open(ihname, 'rt') as ih:
                    header_startend = 0
                    for line in ih:
                        if line == '---\n':
                            header_startend += 1
                            if header_startend == 2:
                                tmpfile.write('vmenu: true\n')
                                tmpfile.write('doctype: tutorial/\n')
                                tmpfile.write(f'langversion: {version}\n')
                                if version == latest:
                                    path = Path(ihname)
                                    latest_path = list(path.parts)
                                    latest_path[latest_path.index(version)] = 'latest'
                                    latest_path = Path(*latest_path)
                                    tmpfile.write(f'redirect_from:\n  - {latest_path}\n')

                        tmpfile.write(line)

                # Replace
                tmpfile.seek(0)
                with open(ihname, 'wt') as ih:
                    ih.write(tmpfile.read())

        print("done.")
