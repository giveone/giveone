$(function() {
  $('#collapse-sub-header').waypoint({
    handler: function(direction) {
      var $nav = $('.sub-header');
      if (direction === "down") return $nav.addClass('shown');
      if ($nav.hasClass('donations')) $('*[data-category]').removeClass('active');
      $nav.removeClass('shown');
    }
  });
});
