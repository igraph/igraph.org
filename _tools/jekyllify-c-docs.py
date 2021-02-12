#!/usr/bin/env python3
"""Script that takes the generated C HTML documentation from igraph and converts
it into a format suitable for Jekyll.

Usage:
    jekyllify-c-docs.py <folder-of-the-igraph-source-tree>
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
---

"""


def fail(msg, code=1):
    print(msg)
    sys.exit(code)


def process_html_file(path):
    tmp_path = path.with_suffix(".html.tmp")
    with tmp_path.open("w") as outfp:
        with path.open("r") as fp:
            in_body = False
            for line in fp:
                if not in_body:
                    if line.startswith("<body"):
                        in_body = True
                        outfp.write(BANNER)
                        outfp.write("{% raw %}\n")
                else:
                    if line.startswith("</body"):
                        in_body = False
                        outfp.write("{% endraw %}\n")

                if in_body:
                    outfp.write(line)

    move(tmp_path, path)


def main():
    parser = ArgumentParser()
    parser.add_argument("source_dir", help="source folder of igraph's C core")
    options = parser.parse_args()

    source_dir = Path(options.source_dir)
    doc_dir = source_dir / "doc" / "html"
    jekyll_dir = source_dir / "doc" / "jekyll"

    if not doc_dir.exists():
        fail(f"Build the HTML docs first; {doc_dir} does not exist")

    rmtree(jekyll_dir)

    if jekyll_dir.exists():
        print(repr(options))

    copytree(doc_dir, jekyll_dir)

    for html_file in jekyll_dir.glob("*.html"):
        process_html_file(html_file)


if __name__ == "__main__":
    sys.exit(main())
