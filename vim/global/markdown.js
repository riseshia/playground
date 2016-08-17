Markdown.dialects.Gruber = {
  lists: function() {
    // TODO: Cache this regexp for certain depths.
    function regex_for_depth(depth) { /* implementation */ }
  },
  "`": function inlineCode( text ) {
    var m = text.match( /(`+)(([\s\S]*?)\1)/ );
      return [ m[1].length + m[2].length ];
    else {
      // TODO: No matching end code found - warn!
      return [ 1, "`" ];
    }
  }
}
