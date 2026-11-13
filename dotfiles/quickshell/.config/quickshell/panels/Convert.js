.pragma library
.import "ConverterEngine.js" as Conv
// Parses "10 km to mi", "30c in f", "5 gb to mb" using Serpantinum's ConverterEngine units.

var ALIASES = {
    "c": "°C", "°c": "°C", "celsius": "°C", "f": "°F", "°f": "°F", "fahrenheit": "°F", "k": "K", "kelvin": "K",
    "meter": "m", "meters": "m", "metre": "m", "metres": "m", "km": "km", "kilometers": "km", "kilometres": "km",
    "mile": "mi", "miles": "mi", "foot": "ft", "feet": "ft", "inch": "in", "inches": "in", "yard": "yd", "yards": "yd",
    "kilo": "kg", "kilos": "kg", "kilogram": "kg", "kilograms": "kg", "gram": "g", "grams": "g", "pound": "lb", "pounds": "lb", "lbs": "lb",
    "stone": "st", "ounce": "oz", "ounces": "oz", "ml": "mL", "l": "L", "liter": "L", "liters": "L", "litre": "L", "litres": "L",
    "gallon": "gal", "gallons": "gal", "pint": "pt", "pints": "pt", "cups": "cup",
    "kmh": "km/h", "kph": "km/h", "kmph": "km/h", "knots": "kn", "mps": "m/s",
    "sec": "s", "secs": "s", "second": "s", "seconds": "s", "mins": "min", "minute": "min", "minutes": "min",
    "hr": "h", "hrs": "h", "hour": "h", "hours": "h", "day": "d", "days": "d", "week": "wk", "weeks": "wk",
    "month": "mo", "months": "mo", "year": "yr", "years": "yr",
    "bits": "bit", "byte": "B", "bytes": "B", "kb": "KB", "mb": "MB", "gb": "GB", "tb": "TB",
    "kib": "KiB", "mib": "MiB", "gib": "GiB", "tib": "TiB",
    "m2": "m²", "km2": "km²", "ft2": "ft²", "sqm": "m²", "sqft": "ft²", "acre": "ac", "acres": "ac", "hectare": "ha", "hectares": "ha"
};

function resolve(u) {
    var raw = u.trim();
    var low = raw.toLowerCase();
    var id = ALIASES[low] || raw;
    for (var c = 0; c < Conv.CATEGORIES.length; c++) {
        var cat = Conv.CATEGORIES[c];
        if (cat === "currency") continue;
        var list = Conv.UNITS[cat];
        for (var i = 0; i < list.length; i++) if (list[i][0] === id) return { cat: cat, id: id };
        for (var j = 0; j < list.length; j++) if (list[j][0].toLowerCase() === low) return { cat: cat, id: list[j][0] };
    }
    return null;
}

// returns { text, value } or null
function run(text) {
    var m = /^\s*(-?\d+(?:[.,]\d+)?)\s*([^\d\s][^\s]*(?:\s(?:oz))?)\s+(?:to|in|->|=)\s+(.+?)\s*$/i.exec(text);
    if (!m) return null;
    var v = parseFloat(m[1].replace(",", "."));
    var a = resolve(m[2]), b = resolve(m[3]);
    if (!a || !b || a.cat !== b.cat) return null;
    var r = Conv.convert(a.cat, a.id, b.id, v, null);
    if (!isFinite(r)) return null;
    var out = Conv.formatValue(r, a.cat).replace("−", "-");
    return { text: m[1] + " " + a.id + " = " + out + " " + b.id, value: out };
}
