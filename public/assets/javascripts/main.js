function query() {
  $.ajax({
    url: '/query',
    data: $('#filter-form').serialize(),
    success: function (res) {
      $('#result').html(res);
    }
  });
}

function toggleFollow() {
  if (window.followInterval)
    clearInterval(window.followInterval);

  if ($('#filter-follow').prop('checked')) {
    query();
    window.followInterval = setInterval(function () {
      query();
    }, 5000);
  }
}

$(document).ready(function() {
  $('#filter-follow').on('change', toggleFollow);
  toggleFollow();

  $('#save-query').on('click', function() {
    console.log("aaa/queries/new?" + $('#filter-form').serialize());
    window.location.href = "/queries/new?" + $('#filter-form').serialize();
  });

  $('#delete-queries').on('click', function() {
    if (confirm("Really?")) {
      $.ajax({
        url: 'queries',
        type: "DELETE",
        success: function() {
          location.reload();
        }
      });
    }
  });

  // $('#time-from').datetimepicker({
  //     locale: 'ru'
  // });
  //
  // $('#time-to').datetimepicker({
  //     locale: 'ru'
  // });
});
