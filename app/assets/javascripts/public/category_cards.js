$(function() {
  var mode = $('.category-cards').attr('data-mode');
  var $categoryCards = $('.category-cards div[data-category]');
  var $categorySelect = $('.category-cards select');
  if (mode === "filter") {
    // Disable unavailable cards
    $categoryCards.each(function(i, card) {
      var $card = $(card);
      var $cardCategory = $card.attr('data-category');
      if ($cardCategory === "all") return;
      var match = $('.activation-cards[data-category='+$cardCategory+']');
      if (match.length === 0) { $card.addClass('unavailable'); }
    });
  }
  var categoryCardsHandler = function() {
    $categoryCards.removeClass('active');
    var clickedCategory = $(this).attr('data-category') || $(this).val();
    if (mode === "autoscroll") {
      var match = $('.donate-card[data-category='+clickedCategory+']');
      if (match.length) { $.smoothScroll({ scrollTarget: match }); }
      return;
    }
    if (mode === "filter") {
      $(this).addClass('active');
      var $activationCards = $('.activation-cards');
      if (clickedCategory === "all") {
        $activationCards.removeClass('filtered');
        if ($activationCards.length) { $.smoothScroll({ scrollTarget: $activationCards[0] }); }
        return;
      }
      $activationCards.addClass('filtered');
      var match = $('.activation-cards[data-category='+clickedCategory+']');
      match.removeClass('filtered');
      if (match.length) { $.smoothScroll({ scrollTarget: match[0] }); }
      return;
    }
  }
  $categorySelect.on('change', categoryCardsHandler);
  $categoryCards.on('click', categoryCardsHandler);
});
