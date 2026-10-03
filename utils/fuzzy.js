// Fuzzy matching for the launcher: does `query` appear in `text` as a subsequence
// ("zn" in "Zen Browser"), and how good is the match?
//
// A ".js" file imported into QML. `.pragma library` makes it one shared copy
// (like a singleton) instead of a copy per QML file that imports it.
.pragma library

// Returns a score (higher = better), or -1 if the letters of `query` don't all appear in order.
function score(query, text) {
    query = query.toLowerCase();
    text = text.toLowerCase();
    if (query.length === 0)
        return 0;

    let total = 0;
    let lastMatch = -1;
    let ti = 0;

    for (const ch of query) {
        const found = text.indexOf(ch, ti);
        if (found < 0)
            return -1; // a letter is missing: no match

        total += 1;
        if (found === lastMatch + 1)
            total += 3; // consecutive letters ("bro" in "browser")
        if (found === 0 || " -_.".includes(text[found - 1]))
            total += 2; // start of a word ("zb" in "Zen Browser")

        lastMatch = found;
        ti = found + 1;
    }

    if (text.startsWith(query))
        total += 10; // typing the beginning of the name is the strongest signal
    return total - text.length * 0.05; // prefer shorter names when otherwise equal
}

// Sort `items` by how well `query` matches `textOf(item)`, dropping non-matches
function filter(query, items, textOf) {
    if (query.length === 0)
        return items;
    return items
        .map(item => ({ item: item, score: score(query, textOf(item)) }))
        .filter(r => r.score >= 0)
        .sort((a, b) => b.score - a.score)
        .map(r => r.item);
}
