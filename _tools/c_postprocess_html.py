#!/usr/bin/env python3
"""Script that takes the generated C HTML documentation from igraph and converts
it into a format suitable for Jekyll.

See Makefile for usage.
"""

import sys

from argparse import ArgumentParser
from pathlib import Path
from shutil import copy, move, rmtree


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


def process_html_file(path, version):
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
                    if line.lstrip().startswith("</body"):
                        in_body = False
                        outfp.write("{% endraw %}\n")
                        break
                    if in_body:
                        outfp.write(line)

    move(tmp_path, path)


def main():
    parser = ArgumentParser()
    parser.add_argument("source_dir", help="source folder of igraph's C core, one version in one subfolder")
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

    for version in versions:
        doc_dir_version = doc_dir / version
        jekyll_dir_version = jekyll_dir / version
        should_skip = (
            (jekyll_dir_version / "index.html").exists() \
            and not (doc_dir_version / "index.html").exists()
        )
        if should_skip:
            continue

        print(jekyll_dir_version)
        if jekyll_dir_version.exists():
            rmtree(jekyll_dir_version)

        jekyll_dir_version.mkdir(parents=True, exist_ok=True)
        for html_file in doc_dir_version.glob("*.html"):
            jekyll_html_file = jekyll_dir_version / html_file.name
            copy(html_file, jekyll_html_file)
            process_html_file(jekyll_html_file, version)


if __name__ == "__main__":
    sys.exit(main())
