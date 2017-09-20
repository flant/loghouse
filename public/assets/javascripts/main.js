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

function getCurrentQuickItem() {
  return $('.super-date-picker__quick-item[data-from="' + $('#time-from').val() + '"][data-to="' + $('#time-to').val() + '"]');
}

function refreshPeriodTitle() {
  var quick_item = getCurrentQuickItem();

  if ($('#time-from').val() == '' && $('#time-to').val() == '') {
    var new_period_title = $('.super-date-picker__period-title').data('default-title');
  } else if (quick_item.length) {
    var new_period_title = quick_item.text();
  } else {
    var new_period_title = $('#time-from').val() + ' – ' + $('#time-to').val();
  }
  $('.super-date-picker__period-title').text(new_period_title);
}

function refreshCurrentQuickItem() {
  var quick_item = getCurrentQuickItem();
  if (quick_item.length) {
    $('.super-date-picker__quick-item').removeClass('btn-primary').removeClass('active').addClass('btn-default');
    $(quick_item).removeClass('btn-default').addClass('btn-primary').addClass('active');
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
    refreshPeriodTitle();
    // update styles
    refreshCurrentQuickItem();
  });

  $('.input-group.date .input-group-addon').on('click', function() {
    $('.super-date-picker__quick-item').removeClass('btn-primary').removeClass('active').addClass('btn-default');
  });

  $('.input-group.date').datetimepicker({locale: 'ru', keepInvalid: true});
  $('.input-group.date input').on('input', function(e) {refreshPeriodTitle()})
  $('.input-group.date').on('dp.change', function(e) {refreshPeriodTitle()})

  refreshPeriodTitle();
  refreshCurrentQuickItem();

  // $('#time-from').datetimepicker({
  //     locale: 'ru'
  // });
  //
  // $('#time-to').datetimepicker({
  //     locale: 'ru'
  // });
});
