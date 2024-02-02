let igraph_doc_versions = {
    c: '0.9.0 0.9.4 0.9.5 0.9.6 0.9.7 0.9.8 0.9.9 0.9.10 0.10.0 0.10.1 0.10.2 0.10.3 0.10.4 0.10.5 0.10.6 0.10.7 0.10.8 0.10.9 master develop',
    r: '1.2.3 1.2.4 1.2.5 1.2.6 1.2.7 1.3.0 1.3.1 1.3.2 1.3.3 1.3.4 1.3.5',
    python: '0.9.6 0.9.7 0.9.8 0.9.9 0.9.10 0.9.11 0.10.0 0.10.1',
};

function version_is_pre_010(version) {
    if (!version.includes(".")) {
        return false;
    }
    let version_parts = version.split(".");
    if (version_parts[0] !== "0") {
        return false;
    }
    return parseInt(version_parts[1]) < 10
}

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
            let href;

            // Post 0.10 python docs change the location of the docs:
            // API docs are now a subfolder of the main docs. However,
            // to help the user here we still link the API subpage if
            // the user comes from a different API version
            if (lang !== 'python' || version_is_pre_010(version)) {
                href = '/' + lang + '/' + doctype + version + '/';
            } else {
                if (doctype === "api/") {
                    href = '/' + lang + '/versions/' + version + '/' + doctype;
                } else {
                    href = '/' + lang + '/versions/' + version + '/';
                }
            }

            child.className = 'dropdown-item';
            child.appendChild(document.createTextNode(version));
            child.setAttribute('href', href);

            node.append(child);
        }
    }
}

