$(function() {
  var mobileMenuGraphic = document.querySelector('.mobile-menu-graphic');
  var mobileMenuContent = document.querySelector('.mobile-header-content');
  mobileMenuGraphic.addEventListener('click', function(event) {
    if (mobileMenuContent.classList.contains('active')) {
      mobileMenuContent.classList.remove('active');
    }else{
      mobileMenuContent.classList.add('active');
    }
  });
});
