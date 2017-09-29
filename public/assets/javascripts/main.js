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
    var new_period_title = $('#superDatePickerBtn').data('default-title');
  } else if (quick_item.length) {
    var new_period_title = quick_item.text();
  } else {
    var new_period_title = $('#time-from').val() + ' – ' + $('#time-to').val();
  }
  $('#superDatePickerBtn').attr('data-original-title', new_period_title);
}

function refreshCurrentQuickItem() {
  var quick_item = getCurrentQuickItem();
  if (quick_item.length) {
    $('.super-date-picker__quick-item').removeClass('btn-primary').removeClass('active').addClass('btn-default');
    $(quick_item).removeClass('btn-default').addClass('btn-primary').addClass('active');
  }
}

$(document).ready(function() {

  // Lib inits
  $('[data-toggle="tooltip"]').tooltip()

  // Ajax magic
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

  // Search params
  var search_params = new SearchParams('.search-params-btn');

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
    // close popover
    search_params.closeAll();
  });

  $('.super-date-picker__reset').on('click', function() {
    $('#time-from').val('');
    $('#time-to').val('');
    refreshPeriodTitle();
    refreshCurrentQuickItem();
    search_params.closeAll();
  });

  $('.input-group.date .input-group-addon').on('click', function() {
    $('.super-date-picker__quick-item').removeClass('btn-primary').removeClass('active').addClass('btn-default');
  });

  $('.input-group.date').datetimepicker({locale: 'ru', keepInvalid: true, useStrict: true});
  $('.input-group.date input').on('input', function(e) {refreshPeriodTitle()})
  $('.input-group.date').on('dp.change', function(e) {refreshPeriodTitle()})

  refreshPeriodTitle();
  refreshCurrentQuickItem();
});
