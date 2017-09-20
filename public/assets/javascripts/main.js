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

  $('.super-date-picker__quick-item').on('click', function() {
    // get data
    var current_item_value_from = $(this).data('from');
    var current_item_value_to = $(this).data('to');
    // set data
    $('#time-from').val(current_item_value_from);
    $('#time-to').val(current_item_value_to);
    // set title
    refreshQuickItemTitle();
    // update styles
    $('.super-date-picker__quick-item').removeClass('btn-primary').removeClass('active').addClass('btn-default');
    $(this).removeClass('btn-default').addClass('btn-primary').addClass('active');
  });

  $('.input-group.date .input-group-addon').on('click', function() {
    $('.super-date-picker__quick-item').removeClass('btn-primary').removeClass('active').addClass('btn-default');
  });

  $('.input-group.date').datetimepicker({locale: 'ru', keepInvalid: true});
  $('.input-group.date input').on('input', function(e) {refreshQuickItemTitle()})
  $('.input-group.date').on('dp.change', function(e) {refreshQuickItemTitle()})

  function refreshQuickItemTitle() {
    var quick_item_selector = '.super-date-picker__quick-item[data-from="' + $('#time-from').val() + '"][data-to="' + $('#time-to').val() + '"]';
    var quick_item = $(quick_item_selector);
    var new_quick_title = quick_item.length ? quick_item.text() : $('#time-from').val() + ' – ' + $('#time-to').val();
    $('.super-date-picker__period-title').text(new_quick_title);
  }

  // $('#time-from').datetimepicker({
  //     locale: 'ru'
  // });
  //
  // $('#time-to').datetimepicker({
  //     locale: 'ru'
  // });
});
