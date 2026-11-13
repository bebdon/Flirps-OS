.pragma library
// Web search shortcuts for the launcher ("!g cats", "!yt lofi", ...).
// Engine URL list based on Serpantinum's SearchProviders.js (ilyamiro, GNU AGPL-3.0).

var BANGS = [
    { bang: "g",   name: "Google",       url: "https://www.google.com/search?q=" },
    { bang: "ddg", name: "DuckDuckGo",   url: "https://duckduckgo.com/?q=" },
    { bang: "b",   name: "Brave Search", url: "https://search.brave.com/search?q=" },
    { bang: "q",   name: "Qwant",        url: "https://www.qwant.com/?q=" },
    { bang: "yt",  name: "YouTube",      url: "https://www.youtube.com/results?search_query=" },
    { bang: "w",   name: "Wikipedia",    url: "https://en.wikipedia.org/w/index.php?search=" },
    { bang: "gh",  name: "GitHub",       url: "https://github.com/search?q=" },
    { bang: "aw",  name: "Arch Wiki",    url: "https://wiki.archlinux.org/index.php?search=" },
    { bang: "aur", name: "AUR",          url: "https://aur.archlinux.org/packages?K=" },
    { bang: "r",   name: "Reddit",       url: "https://www.reddit.com/search/?q=" },
    { bang: "m",   name: "Maps",         url: "https://www.openstreetmap.org/search?query=" }
];

var DEFAULT_BANG = "q";   // used for "Search the web for …"

function find(bang) {
    for (var i = 0; i < BANGS.length; i++) if (BANGS[i].bang === bang) return BANGS[i];
    return null;
}

// "!yt lofi beats" -> { engine, query } or null
function parse(text) {
    var m = /^!(\w+)\s*(.*)$/.exec(text);
    if (!m) return null;
    var e = find(m[1].toLowerCase());
    return e ? { engine: e, query: m[2] } : null;
}

function url(engine, query) { return engine.url + encodeURIComponent(query); }
