#!/usr/bin/env python3
"""Script that takes the generated C HTML documentation from igraph and converts
it into a format suitable for Jekyll.

See Makefile for usage.
"""

import sys

from argparse import ArgumentParser
from pathlib import Path
from shutil import copytree, move, rmtree


BANNER = """\
---
layout: c-manual
title: igraph Reference Manual
mainheader: igraph Reference Manual
lead: For using the igraph C library
vmenu: true
doctype: html/
"""


def fail(msg, code=1):
    print(msg)
    sys.exit(code)


def process_html_file(path, version, latest_version):
    tmp_path = path.with_suffix(".html.tmp")
    with tmp_path.open("w") as outfp:
        outfp.write(BANNER)
        outfp.write(f'langversion: {version}\n')
        outfp.write('---\n\n')
        outfp.write("{% raw %}\n")

        with path.open("r") as fp:
            in_body = False
            for line in fp:
                if not in_body:
                    if line.startswith("<body"):
                        in_body = True
                else:
                    if line.startswith("</body"):
                        in_body = False
                        outfp.write("{% endraw %}\n")
                        break
                if in_body:
                    outfp.write(line)

    move(tmp_path, path)


def main():
    parser = ArgumentParser()
    parser.add_argument("source_dir", help="source folder of igraph's C core")
    parser.add_argument("out_dir", help="output folder of igraph's C core")
    parser.add_argument("versions", help="versions to build")
    parser.add_argument("latest", help="latest version to redirect")
    options = parser.parse_args()

    doc_dir = Path(options.source_dir)
    jekyll_dir = Path(options.out_dir)
    versions = options.versions.split()
    latest = options.latest

    if not doc_dir.exists():
        fail(f"Build the HTML docs first; {doc_dir} does not exist")

    if jekyll_dir.exists():
        rmtree(jekyll_dir)

    copytree(doc_dir, jekyll_dir)

    for version in versions:
        jekyll_dir_version = jekyll_dir / version
        print(jekyll_dir_version)
        for html_file in jekyll_dir_version.glob("*.html"):
            print(html_file)
            process_html_file(html_file, version, latest)


if __name__ == "__main__":
    sys.exit(main())
