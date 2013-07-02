var required_fields = [
  '#customer_full_name', 
  '#customer_phone', 
  '#shipping_full_name', 
  '#shipping_street_line1', 
  '#shipping_city', 
  '#shipping_state', 
  '#shipping_zip',
  '#billing_full_name',
  '#card_number',
  '#security_code',
  '#exp_month',
  '#exp_year',
  '#exp_month'
]

var checkboxes = [
  '#copyright_policy',
  '#privacy_policy',
  '#terms_of_service'
]

function appendErrorClass(input_id){
  $(input_id);
}

function validForm(){
  valid=true;
  for (i=0;required_fields.length>i;i++){
    if ($(required_fields[i]).val().length === 0){
      $(required_fields[i]).addClass('error');
      $(".payment-errors").html("<p>Please fill out all required form fields.</p>");
      valid=false; 
    }
  }
  for (i=0;checkboxes.length>i;i++){
    if (!$(checkboxes[i]).is(':checked')){
      $(checkboxes[i]).addClass('error');
      $(".terms-errors").html("<p>Please agree to all conditions of sale.</p>");
      valid=false; 
    }
  }
  var sum = 0;
  $('input[class="item-input"]').each(function() {
    sum += Number($(this).val());
  });
  if (sum==0) {
    $(".payment-errors").html("<p>Please select an item to order.</p>");
    valid=false
  }
  
  return valid;
  
}