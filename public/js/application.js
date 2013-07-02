$(document).ready(function() {
  
  $(".item a.btn.plus").click(function(event) {
   i = $("input[name='" + $(this).attr('name') + "']");
   n = parseInt(i.attr('value'));
   if (n < 9) { i.attr('value',  n + 1 ); }  
  });
  
  $(".item a.btn.minus").click(function(event) {
   i = $("input[name='" + $(this).attr('name') + "']");
   n = parseInt(i.attr('value'));
   if (n > 0) { i.attr('value',  n - 1 ); }  
  });

  $(".item img").click(function(event) {
   i = $("input[name='" + $(this).attr('name') + "']");
   n = parseInt(i.attr('value'));
   if (n < 10) { i.attr('value',  n + 1 ); }  
  });


  $("a.visibility_button").click(function(event) {
    a = $(this).attr('id')
    $("div[id='" + a + "']").toggle(); 
  });
  
  var date = $( "#datepicker" );
  if (date.length) { date.datepicker(); }

});
