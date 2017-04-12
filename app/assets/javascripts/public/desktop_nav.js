$(function() {
  $('#collapse-desktop-nav').waypoint({
    handler: function(direction) {
      var $nav = $('#desktop_nav');
      if (direction === "down") return $nav.addClass('collapsed');
      $nav.removeClass('collapsed');
    }
  });
});
