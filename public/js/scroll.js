$(document).ready(function() {
  var row = 5;
  var loading = false;

  function nearBottomOfPage() {
    return $(window).scrollTop() > $(document).height() - $(window).height() - 300;
  }

  $(window).scroll(function(){
    if (loading) {
      return;
    }

    if(nearBottomOfPage()) {
      loading=true;
      row++;
      $.ajax({
        url: '/videos',
        type: 'post',
        data: { index: row*3, number: 3 },
        dataType: 'html',
        success: function(html) {
          $("#videos").append(html)
          loading=false;
        }
      });
    }
  });

});
