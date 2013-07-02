
function stripeResponseHandler(status, response) {
    if (response.error) {
        // re-enable the submit button
        $('.submit-button').removeAttr("disabled");
        //show the errors on the form
        $(".payment-errors").html("<p>" + response.error.message + "</p>");
        console.log( typeof(response.error.param)+ response.error.param );
          switch(response.error.param)
            {
            case "number":
              $("#card_number").addClass('error');
              break;
            case "cvc":
              $("#security_code").addClass('error');
              break;
            case "exp_month":
              $("#exp_month").addClass('error');
              break;
            case "exp_year":
              $("#exp_year").addClass('error');
              break;
            default:
              console.log("Unknow error");
            }
    } else {
        var form$ = $("#payment-form");
        // token contains id, last4, and card type
        var token = response['id'];
        // insert the token into the form so it gets submitted to the server
        form$.append("<input type='hidden' name='stripeToken' value='" + token + "'/>");
        // and submit
        form$.get(0).submit();
    }
}

$(document).ready(function() {

  $('.submit-button').removeAttr("disabled");

  $("#payment-form").submit(function(event) {

    if (!validForm()) {return false;}

    $('.submit-button').attr("disabled", "disabled");
    
    Stripe.createToken({
        number: $('.card-number').val(),
        cvc: $('.card-cvc').val(),
        exp_month: $('.card-expiry-month').val(),
        exp_year: $('.card-expiry-year').val()
    }, stripeResponseHandler);

    // prevent the form from submitting with the default action
    return false;
  });
});
