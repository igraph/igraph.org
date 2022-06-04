let igraph_doc_versions = {
    c: '0.9.0 0.9.4 0.9.5 0.9.6 0.9.7 0.9.8 0.9.9 master develop',
    r: '1.2.3 1.2.4 1.2.5 1.2.6 1.2.7 1.3.0',
    python: '0.9.6 0.9.7 0.9.8 0.9.9 0.9.10 master develop',
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

