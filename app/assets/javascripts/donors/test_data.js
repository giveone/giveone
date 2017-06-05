$(function() {
  $NS = $('body#donors_new, body#donors_create');

  $('#donate_test_data_button').click(function(e) {
    e.preventDefault();
    $('#donor_card_attributes_email').val("admin+giveone-test-data-" + Math.round(Math.random() * 1000000) + "@give-one.org");
    $('#donor_card_attributes_name').val("Dmitri Vassilev");
    $('#donor_card_attributes_card_number').val("4242424242424242").trigger('paste');
    $('#donor_card_attributes_cvc').val("1234");
    $('#donor_card_attributes_card_type').val("amex");
    $('#donor_card_attributes_exp_month').val("12");
    $('#donor_card_attributes_exp_year').val("2020");
    $('#donor_card_attributes_address1').val("123 Test Street");
    $('#donor_card_attributes_city').val("New York");
    $('#donor_card_attributes_state').val("NY");
    $('#donor_card_attributes_zip').val("10002").trigger("keyup");
    $('#donor_card_attributes_name').focus();
  });

});
