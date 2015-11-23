var translationsWithColon = {};

function escapeRegExp(s) {
  return s.replace(/[-/\\^$*+?.()|[\]{}]/gi, '\\$&');
}

function imageFor(code) {
  code = code.toLowerCase();
  var url = Discourse.Emoji.urlFor(code);
  if (url) {
    var code = ':' + code + ':';
    return ['img', { href: url, title: code, 'class': 'emoji', alt: code }];
  }
}

function checkPrev(prev) {
  if (prev && prev.length) {
    var lastToken = prev[prev.length-1];
    if (lastToken && lastToken.charAt) {
      var lastChar = lastToken.charAt(lastToken.length-1);
      if (!/\W/.test(lastChar)) return false;
    }
  }
  return true;
}

Object.keys(Discourse.Emoji.translations).forEach(function (t) {
  if (t[0] === ':') {
    translationsWithColon[t] = Discourse.Emoji.translations[t];
  } else {
    var replacement = Discourse.Emoji.translations[t];
    Discourse.Dialect.inlineReplace(t, function (token, match, prev) {
      if (!Discourse.SiteSettings.enable_emoji) { return token; }
      return checkPrev(prev) ? imageFor(replacement) : token;
    });
  }
});

var translationColonRegexp = new RegExp(Object.keys(translationsWithColon).map(function (t) {
                                           return "(" + escapeRegExp(t) + ")";
                                         }).join("|"));

Discourse.Dialect.registerEmoji = function(code, url) {
  code = code.toLowerCase();
  Discourse.Emoji.extendedEmoji[code] = url;
};

// This method is used by PrettyText to reset custom emojis in multisites
Discourse.Dialect.resetEmojis = function() {
  Discourse.Emoji.extendedEmoji = {};
};

Discourse.Dialect.registerInline(':', function(text, match, prev) {
  if (!Discourse.SiteSettings.enable_emoji) { return; }

  var endPos = text.indexOf(':', 1),
      firstSpace = text.search(/\s/),
      contents;

  if (!checkPrev(prev)) { return; }

  // If there is no trailing colon, check our translations that begin with colons
  if (endPos === -1 || (firstSpace !== -1 && endPos > firstSpace)) {
    translationColonRegexp.lastIndex = 0;
    var m = translationColonRegexp.exec(text);
    if (m && m[0] && text.indexOf(m[0]) === 0) {
      // Check outer edge
      var lastChar = text.charAt(m[0].length);
      if (lastChar && !/\s/.test(lastChar)) return;
      contents = imageFor(translationsWithColon[m[0]]);
      if (contents) {
        return [m[0].length, contents];
      }
    }
    return;
  }

  // Simple find and replace from our array
  var between = text.slice(1, endPos);
  contents = imageFor(between);
  if (contents) {
    return [endPos+1, contents];
  }
});

Discourse.Markdown.whiteListTag('img', 'class', 'emoji');

PreloadStore.get("customEmoji").forEach(function(emoji) {
  Discourse.Dialect.registerEmoji(emoji.name, emoji.url);
});
