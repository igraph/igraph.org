---
layout: none
---

let igraph_doc_versions = {
    c: '{% include igraph-cversions %}',
    r: '{% include igraph-rversions %}',
    python: '{% include igraph-pyversions %}',
};

function generateVersionSwitcher(selector, lang, doctype) {
    let i, n;
    let node;
    let versions = igraph_doc_versions[lang];

    if (typeof versions === 'object') {
        versions = versions[doctype.replace("/", "")];
    }

    node = document.querySelector(selector);
    if (!node) {
        return;
    }

    node.innerHTML = '';

    if (typeof versions !== 'string' || versions.length === 0) {
        return;
    }

    versions = versions.split(' ');
    versions.push('latest');
    versions.reverse();

    n = versions.length;

    for (i = 0; i < n; i++) {
        let version = versions[i];
        if (version && typeof version == 'string' && version.length > 0) {
            let child = document.createElement("a");
            let href = '/' + lang + '/' + doctype + version + '/';

            child.className = 'dropdown-item';
            child.appendChild(document.createTextNode(version));
            child.setAttribute('href', href);

            node.append(child);
        }
    }
}

