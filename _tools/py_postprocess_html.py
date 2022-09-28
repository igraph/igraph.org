#!/usr/bin/env python3
# Embed API documentation created by sphinx into the igraph.org style, including
# menubar, versioning, etc.
import os
import re
from pathlib import Path
import shutil
import glob
import tempfile
import argparse

def safeint(x):
    try:
        return int(x)
    except Exception:
        return x


def postprocess_docs(folder, version):
    '''Change Jekyll header to embed the Python docs into igraph.org'''
    header_pydoctor = (
        "---\n"
        "layout: pydoctor\n"
        "title: python-igraph API reference\n"
        "mainheader: python-igraph API reference\n"
        "lead: List of all classes, functions and methods in python-igraph\n")
    # Capture main folder and subfolders (e.g. API, tutorials)
    inhtml = glob.glob(str(folder)+'/'+version+'/*.html')
    inhtml += glob.glob(str(folder)+'/'+version+'/*/*.html')
    inhtml += glob.glob(str(folder)+'/'+version+'/*/*/*.html')
    for ihname in inhtml:
        hf = os.path.basename(ihname)
        print(f'Converting {hf}...')

        # pydoctor-made files need a special header
        input_file_is_api = '/api/' in ihname
        with tempfile.TemporaryFile(dir='/tmp', mode='w+t') as tmpfile:
            with open(ihname, 'rt') as ih:
                yaml_header_lines = []
                line = next(ih, None)
                if line.startswith("---"):
                    yaml_header_lines.append(line)
                    for line in ih:
                        if line.startswith('vmenu: '):
                            continue
                        if line.startswith('langversion: '):
                            continue
                        if line.startswith("---"):
                            break
                        yaml_header_lines.append(line)
                    line = ""
                header_extant = ''.join(yaml_header_lines)

                # For pydoctor-made files, replace the header
                if input_file_is_api:
                    tmpfile.write(header_pydoctor)
                    tmpfile.write('doctype: api/\n')
                # For non-pydoctor-made files, append to the header
                else:
                    tmpfile.write(header_extant)
                    tmpfile.write('doctype: tutorial/\n')

                # Common Jekyll options
                tmpfile.write('vmenu: true\n')
                tmpfile.write('lang: python\n')
                tmpfile.write(f'langversion: {version}\n')
                tmpfile.write('---\n')

                if input_file_is_api:
                    tmpfile.write('{% raw %}\n')

                # Rest of the file (content)
                for line in ih:
                    tmpfile.write(line)

                if input_file_is_api:
                    tmpfile.write('{% endraw %}\n')

            # Replace temp file into input file location
            tmpfile.seek(0)
            with open(ihname, 'wt') as ih:
                ih.write(tmpfile.read())


def postprocess_API_old(folder, version):
    '''Postprocess API docs < 0.10 since they are built separately'''
    header_pydoctor = (
        "---\n"
        "layout: pydoctor\n"
        "title: python-igraph API reference\n"
        "mainheader: python-igraph API reference\n"
        "lead: List of all classes, functions and methods in python-igraph\n"
        "vmenu: true\n"
        "doctype: api/\n")

    header_epydoc = (
        "---\n"
        "layout: epydoc\n"
        "title: python-igraph manual\n"
        "mainheader: python-igraph manual\n"
        "lead: For using igraph from Python\n"
        "vmenu: true\n"
        "doctype: api/\n")

    print('Processing version: '+version)

    # Around 2021, we transitioned to pydoctor but did not have a sphinx
    # extension to convert the output to Jekyll yet
    if version not in ['0.8.1', '0.9.0']:
        docgenerator = 'pydoctor'
        header = header_pydoctor
    # Pre-2021 versions used Epydoc to generate the documentation
    else:
        docgenerator = 'epydoc'
        header = header_epydoc

    # Add header, side menu, and other goodies from the igraph.org page
    # that pydoctor cannot know about. For versions around 2021 and older,
    # also convert the html from pydoctor/epydoc into Jekyll-palatable code
    inhtml = glob.glob(str(folder)+'/'+version+'/*.html')
    for ihname in inhtml:
        hf = os.path.basename(ihname)
        print(f'Converting {hf}...')

        with tempfile.TemporaryFile(dir='/tmp', mode='w+t') as tmpfile:
            # YAML header
            tmpfile.write(header)
            tmpfile.write(f'langversion: {version}\n')
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


def postprocess_tutorial_old(folder, version):
    # Convert HTML from sphinx (excluding API) into Jekyll input
    # Because we cut out the API and put it into another folder,
    # we need to correct all the links
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

                    tmpfile.write(line)

            # Replace
            tmpfile.seek(0)
            with open(ihname, 'wt') as ih:
                ih.write(tmpfile.read())

    print("done.")


if __name__ == '__main__':

    pa = argparse.ArgumentParser()
    pa.add_argument('build_folder')
    pa.add_argument('versions')
    args = pa.parse_args()

    build_folder = Path(args.build_folder)
    versions = args.versions.strip("'").split(' ')
    folder = Path('python')

    # Remove stale destination folders
    shutil.rmtree(folder / 'versions', ignore_errors=True)
    shutil.rmtree(folder / 'api', ignore_errors=True)
    shutil.rmtree(folder / 'tutorial', ignore_errors=True)

    for version in versions:
        print('Processing version: '+version)
        version_parts = tuple(safeint(x) for x in version.split("."))

        # Current docs use sphinx extensions to produce a single doc tree
        if version in ['master', 'develop'] or version_parts >= (0, 10):
            os.makedirs(folder / 'versions', exist_ok=True)
            shutil.copytree(
                    build_folder / 'doc' / 'versions' / version,
                    folder / 'versions' / version,
                    )
            # This only ensures a consistent style with the rest of igraph.org
            postprocess_docs(folder / 'versions', version)

        # Older docs produce two doc parts, API and tutorial, handled separately
        else:
            os.makedirs(folder / 'api', exist_ok=True)
            shutil.copytree(
                    build_folder / 'doc' / 'api_versions' / version,
                    folder / 'api' / version,
                    )
            postprocess_API_old(folder / 'api', version)

            os.makedirs(folder / 'tutorial', exist_ok=True)
            shutil.copytree(
                    build_folder / 'doc' / 'tutorial' / version,
                    folder / 'tutorial' / version,
                    )
            postprocess_tutorial_old(folder / 'tutorial', version)
