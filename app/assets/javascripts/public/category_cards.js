$(function() {
  var mode = $('.category-cards').attr('data-mode');
  var $categoryCards = $('.category-cards div[data-category]');
  var $categoryHeaderItems = $('.sub-header div[data-category]');
  var $categorySelect = $('.category-cards select');
  var disableUnavailable = function(i, card) {
    var $card = $(card);
    var $cardCategory = $card.attr('data-category');
    if ($cardCategory === "all") return;
    var match = $('.activation-cards[data-category='+$cardCategory+']');
    if (match.length === 0) { $card.addClass('unavailable'); }
  };
  if (mode === "filter") {
    $categoryCards.each(disableUnavailable);
    $categoryHeaderItems.each(disableUnavailable);
  }
  var categoryCardsHandler = function() {
    $categoryCards.removeClass('active');
    $categoryHeaderItems.removeClass('active');
    var clickedCategory = $(this).attr('data-category') || $(this).val();
    $('*[data-category='+clickedCategory+']').addClass('active');
    if (mode === "autoscroll") {
      var match = $('.donate-card[data-category='+clickedCategory+']');
      if (match.length) { $.smoothScroll({ scrollTarget: match, offset: -140 }); }
      return;
    }
    if (mode === "filter") {
      $('*[data-category='+clickedCategory+']').addClass('active');
      var $activationCards = $('.activation-cards');
      if (clickedCategory === "all") {
        $activationCards.removeClass('filtered');
        if ($activationCards.length) { $.smoothScroll({ scrollTarget: $activationCards[0], offset: -220 }); }
        return;
      }
      $activationCards.addClass('filtered');
      var match = $('.activation-cards[data-category='+clickedCategory+']');
      match.removeClass('filtered');
      if (match.length) { $.smoothScroll({ scrollTarget: match[0], offset: -220 }); }
      return;
    }
  }
  $categorySelect.on('change', categoryCardsHandler);
  $categoryCards.on('click', categoryCardsHandler);
  $categoryHeaderItems.on('click', categoryCardsHandler);
});
