function commonTimestamp() {
  return moment().format('YYYY-MM-DD HH:mm:ss');
}

function commonShowError(text) {
  var $errorContainer = $('.error-container .error-container__content');
  $errorContainer.append("<div class=\"alert alert-danger alert-dismissible\" role=\"alert\">" + text + "<button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-label=\"Close\"><span aria-hidden=\"true\">&times;</span></button></div>");
}

function queryOlder() {
  if (window.query_older_is_loading != true) {
    console.log(commonTimestamp() + ' Started loading older entries.');
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
        if (res != '') {
          console.log(commonTimestamp() + ' Loaded older entries to monitor.');
          $resultContainer.append(res);
          oldest = $resultContainer.find('div:last-child .logs-result__entry-timestamp').text();
          $resultContainer.data('entry-oldest', oldest);
        } else {
          console.log(commonTimestamp() + ' No more older entries.');
          $resultContainer.append('<div class="logs-result__breakpoint">--- END ---</div>');
        }
        $resultContainer.removeClass('logs-result__container_loading-older');
        window.query_older_is_loading = false;
      },
      error: function(res) {
        commonShowError('Something went wrong during loading older entries. Error log available at console.');
        console.log(commonTimestamp() + ' Something went wrong during loading older entries:');
        console.log(res);
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
        if (res != '') {
          console.log(commonTimestamp() + ' Loaded new entries to monitor.');
          $resultContainer.prepend(res);
          newest = $resultContainer.find('div:first-child .logs-result__entry-timestamp').text();
          $resultContainer.data('entry-newest', newest);
        } else {
          console.log(commonTimestamp() + ' Monitor is up to date.');
        }
        $resultContainer.removeClass('logs-result__container_loading-newer');
        window.query_newer_is_loading = false;
      },
      error: function(res) {
        commonShowError('Something went wrong during loading newer entries. Error log available at console.');
        console.log(commonTimestamp() + ' Something went wrong during loading newer entries:');
        console.log(res);
        $resultContainer.removeClass('logs-result__container_loading-newer');
        window.query_newer_is_loading = false;
      }
    });
  }
}

function queryNewerPlay() {
  if (window.newerInterval) {
    clearInterval(window.newerInterval);
  }
  queryNewer();
  window.newerInterval = setInterval(function () {
    queryNewer();
  }, 5000);
  console.log(commonTimestamp() + ' Started auto-update.');
}

function queryNewerPause() {
  clearInterval(window.newerInterval);
  console.log(commonTimestamp() + ' Paused auto-update.');
}

function addBreakpoint() {
  var $resultContainer = $('.logs-result__container');
  $resultContainer.prepend('<div class="logs-result__breakpoint">--- Breakpoint at ' + commonTimestamp() + ' ---</div>');
}

function getCurrentQuickItem() {
  return $('.super-date-picker__quick-item[data-from="' + $('#time-from').val() + '"][data-to="' + $('#time-to').val() + '"]');
}

function refreshPeriodTitle() {
  var quick_item = getCurrentQuickItem();
  var new_period_title;

  if ($('#time-from').val() == '' && $('#time-to').val() == '') {
    new_period_title = $('#superDatePickerBtn').data('default-title');
  } else if (quick_item.length) {
    new_period_title = quick_item.text();
  } else {
    new_period_title = $('#time-from').val() + ' – ' + $('#time-to').val();
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

  // Save query
  $('#save-query').on('click', function() {
    window.location.href = "/queries/new?" + $('#filter-form').serialize();
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
    submitForm();
  });

  $('.super-date-picker__reset').on('click', function() {
    $('#time-from').val('');
    $('#time-to').val('');
    refreshPeriodTitle();
    refreshCurrentQuickItem();
    search_params.closeAll();
    submitForm();
  });

  $('.input-group.date .input-group-addon').on('click', function() {
    $('.super-date-picker__quick-item').removeClass('btn-primary').removeClass('active').addClass('btn-default');
  });

  $('.input-group.date').datetimepicker({locale: 'ru', keepInvalid: true, useStrict: true});
  $('.input-group.date input').on('input', function(e) {refreshPeriodTitle();});
  $('.input-group.date').on('dp.change', function(e) {refreshPeriodTitle();});

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

  // Breakpoint
  var $breakpointBtn = $('#breakpointBtn');

  $breakpointBtn.on('click', function() {
    addBreakpoint();
  });

  // Infinite scroll
  var paginatable_element = $('.logs-result__container');
	paginatable_element.scroll(function() {
		if (paginatable_element.scrollTop() == 0) {
      queryOlder();
		}
	});

  // Manage queries
  $('#delete-queries').on('click', function() {
    if (confirm("Are you sure?")) {
      $.ajax({
        url: 'queries',
        type: "DELETE",
        success: function() {
          location.reload();
        },
        error: function(res) {
          commonShowError('Something went wrong during deleting all queries. Error log available at console.');
          console.log(commonTimestamp() + ' Something went wrong during deleting all queries:');
          console.log(res);
        }
      });
    }
  });

  $('.delete-query').on('click', function() {
    if (confirm("Are you sure?")) {
      id = $(this).data('id');
      $.ajax({
        url: 'queries/' + id,
        type: "DELETE",
        success: function() {
          location.reload();
        },
        error: function(res) {
          commonShowError('Something went wrong during deleting query. Error log available at console.');
          console.log(commonTimestamp() + ' Something went wrong during deleting query:');
          console.log(res);
        }
      });
    }
  });

  if($('.sortable-queries').length) {
    sortable('.sortable-queries', {
      items: 'tr',
      handle: '.sortable-handle',
      placeholder: "<tr><td colspan=\"7\" align=\"center\">Query will be moved here</tr>",
      forcePlaceholderSize: false
    });

    sortable('.sortable-queries')[0].addEventListener('sortstop', function(e) {
      var new_order = [];
      $('.sortable-queries tr').each(function() {
        new_order.push($(this).data('query-id'));
      });
      $.ajax({
        url: '/queries/update_order',
        dataType: 'json',
        data: {'new_order': JSON.stringify(new_order)},
        type: 'PUT',
        success: function(res) {
          console.log(commonTimestamp() + ' Updated queries order.');
        },
        error: function(res) {
          commonShowError('Something went wrong during sorting queries. Error log available at console.');
          console.log(commonTimestamp() + ' Something went wrong during sorting queries:');
          console.log(res);
        }
      });
    });
  }

  // Autosend query
  submitForm = function () {
    $('#filter-form').submit();
  };

  $(document).on('change', '#query', submitForm);
});
