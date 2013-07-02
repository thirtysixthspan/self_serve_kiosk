function Card() 
{

  var card = this;
  
  card.values = {};
  card.valueNames = [
		"name", 
		"last4",
		"email",
		"card_token"
  ];
  
  card.set_defaults = function() {
    card.values.name = '';
    card.values.email = '';
    card.values.last4 = '';    
  };

  card.update = function(data) {
    card.valueNames.map( function(name) { 
      if (data.hasOwnProperty(name)) { card.values[name] = data[name]; }
    });
    if (data.hasOwnProperty('last4')) { 
      $("input.btn").removeAttr("disabled");
      $('#make-purchase').animate({opacity:0.75}, 500,
      function() {
        $('#make-purchase').animate({opacity:1}, 500);       
      }); 
    }
    

    $('#name-display').html(card.values.name);
    $('#name-input').val(card.values.name);
    $('#last4-display').html(card.values.last4);
    if ($('#email-input').val()=="") {
      $('#email-input').val(card.values.email);
    }  
    $('#card-token-input').val(card.values.card_token);

  };

  card.request_card_swipe = function() {
    $.getJSON('/store/request_card_swipe', function(data) { card.update(data); });
  };
  
  card.read_card_swipe = function() {
  	var query = {};
  	query.card_token = $('input[id=card-token-input]').val();
    $.getJSON('/store/read_card_swipe', query, function(data) { card.update(data); });
  };

  card.initialize = function() {
    card.set_defaults();
    card.request_card_swipe();    
    setInterval(function() { card.read_card_swipe(); }, 1000);
  };
      
}

var card = new Card();
card.initialize();
