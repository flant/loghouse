function queryOlder(timestamp) {
  if (window.query_older_is_loading != true) {
    window.query_older_is_loading = true;
    var $resultContainer = $('.logs-result__container');
    var oldest = $resultContainer.data('entry-oldest');
    var data = $('#filter-form').serialize();
    data = data + '&older_than=' + oldest;

    $resultContainer.addClass('logs-result__container_loading-older');

    $.ajax({
      url: '/query',
      data: data,
      success: function (res) {
        $resultContainer.append(res);
        oldest = $resultContainer.find('div:last-child .logs-result__entry_timestamp').text();
        $resultContainer.data('entry-oldest', oldest);
        $resultContainer.removeClass('logs-result__container_loading-older');
        window.query_older_is_loading = false;
      }
    });
  }
}

function queryNewer() {
  if (window.query_newer_is_loading != true) {
    window.query_newer_is_loading = true;
    var $resultContainer = $('.logs-result__container');
    var newest = $resultContainer.data('entry-newest');
    var data = $('#filter-form').serialize();
    data = data + '&newer_than=' + newest;

    $resultContainer.addClass('logs-result__container_loading-newer');

    $.ajax({
      url: '/query',
      data: data,
      success: function (res) {
        $resultContainer.prepend(res);
        newest = $resultContainer.find('div:last-child .logs-result__entry_timestamp').text();
        $resultContainer.data('entry-newest', newest);
        $resultContainer.removeClass('logs-result__container_loading-newer');
        window.query_newest_is_loading = false;
      }
    });
  }
}

function queryNewerPlay() {
  if (window.followInterval) {
    clearInterval(window.followInterval);
  }
  queryNewer();
  window.followInterval = setInterval(function () {
    queryNewer();
  }, 5000);
}

function queryNewerPause() {
  clearInterval(window.followInterval);
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
  //$('#superDatePickerBtn').attr('data-original-title', new_period_title);
  $('.super-date-picker__period-title').text(new_period_title);
}

function refreshCurrentQuickItem() {
  var quick_item = getCurrentQuickItem();
  if (quick_item.length) {
    $('.super-date-picker__quick-item').removeClass('btn-success').removeClass('btn-inverse').removeClass('active').addClass('btn-default');
    $(quick_item).removeClass('btn-default').addClass('btn-success').addClass('btn-inverse').addClass('active');
  }
}

$(document).ready(function() {

  // Lib inits
  $('[data-toggle="tooltip"]').tooltip();

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

  $('.delete-query').on('click', function() {
    if (confirm("Really?")) {
      id = $(this).data('id');
      $.ajax({
        url: 'queries/' + id,
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

  // Play/pause

  var $playBtn = $('#playBtn');
  var $pauseBtn = $('#pauseBtn');

  $playBtn.on('click', function() {
    $playBtn.addClass('active').removeClass('disabled');
    $pauseBtn.removeClass('disabled');
    queryNewerPlay();
  });

  $pauseBtn.on('click', function() {
    $pauseBtn.addClass('disabled');
    $playBtn.removeClass('active').removeClass('disabled');
    queryNewerPause();
  });

  // Infinite scroll
  var paginatable_element = $('.logs-result__container');
	paginatable_element.scroll(function() {
		if (paginatable_element.scrollTop() == 0) {
      queryOlder();
		}
	});
});
