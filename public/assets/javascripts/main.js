window.available_keys = [];
window.hidden_keys = [];
window.selected_keys = (Cookies.get('selected_keys') ? JSON.parse(Cookies.get('selected_keys')) : []);
window.keys_option = Cookies.get('keys_option') || 'hide';

function commonTimestamp() {
  return moment().format('YYYY-MM-DD HH:mm:ss');
}

function commonShowError(text) {
  var $errorContainer = $('.error-container .error-container__content');
  $errorContainer.append("<div class=\"alert alert-danger alert-dismissible\" role=\"alert\">" + text + "<button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-label=\"Close\"><span aria-hidden=\"true\">&times;</span></button></div>");
}

function addCSSRule(sheet, selector, rules, index) {
  if('insertRule' in sheet) {
    sheet.insertRule(selector + '{' + rules + '}', index);
  }
  else if('addRule' in sheet) {
    sheet.addRule(selector, rules, index);
  }
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
          updateAvailableKeys();
          updateAvailableKeysStyles();
          updateSelectedKeysClasses();
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
          updateAvailableKeys();
          updateAvailableKeysStyles();
          updateSelectedKeysClasses();
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

function initHideShow() {
  updateAvailableKeys();
  initHideShowWidget();
  initAvailableKeysStyles();
  updateAvailableKeysStyles();
  updateSelectedKeysClasses();
}

function initHideShowWidget() {
  // init search params widget
  $('#hide-show-keys-select').select2({
    placeholder: 'Select some keys',
    multiple: true,
    theme: "bootstrap",
    data: window.available_keys
  });

  $('#hide-show-keys-select').val(window.selected_keys).trigger('change');

  $('#hide-show-keys-select').on("select2:select", function(e) {
    window.selected_keys.push(e.params.data.id);
    Cookies.set('selected_keys', JSON.stringify(window.selected_keys));
    updateSelectedKeysClasses();
  });
  $('#hide-show-keys-select').on("select2:unselect", function(e) {
    window.selected_keys.delete(e.params.data.id);
    Cookies.set('selected_keys', JSON.stringify(window.selected_keys));
    updateSelectedKeysClasses();
  });
  $('.hide-show-keys-btn[data-option=' + window.keys_option + ']').addClass('active');
  $('.hide-show-keys-btn').each(function() {
    $(this).on('click', function() {
      $(this).parent().find('.hide-show-keys-btn').removeClass('active');
      $(this).addClass('active');
      window.keys_option = $(this).data('option');
      Cookies.set('keys_option', window.keys_option);
      updateSelectedKeysClasses();
    });
  });
}

function updateAvailableKeys() {
  var el = $('#result');
  el.find('span[data-key]').each(function() {
    var key = $(this).data('key');
    if (window.available_keys.indexOf(key) < 0)
      window.available_keys.push(key);
  });
  if (window.available_keys.length != 0) {
    window.available_keys.sort();
    $('.hide-show-keys-toggle').removeClass('disabled');
  }  else {
    window.available_keys = [];
    window.selected_keys = [];
    Cookies.set('selected_keys', JSON.stringify(window.selected_keys));
    $('.hide-show-keys-toggle').addClass('disabled');
  }
}

function initAvailableKeysStyles() {
  window.keys_style = document.createElement('style');
  window.keys_style.appendChild(document.createTextNode('')); // WebKit hack
  document.head.appendChild(window.keys_style);
}

function updateAvailableKeysStyles() {
  while (window.keys_style.sheet.cssRules.length > 0) {
    window.keys_style.sheet.deleteRule(0);
  }
  for (var i = 0; i < window.available_keys.length; i++) {
    key = window.available_keys[i];
    key_css_friendly = key.replace('.', '_');
    addCSSRule(window.keys_style.sheet, 'body.hide_' + key_css_friendly + ' #result span[data-key="' + key + '"]', 'display: none', 0);
  }
}

function updateSelectedKeysClasses() {
  var body = $('body');
  body.removeClass(function (index, className) {
    return (className.match (/\bhide_\S+/g) || []).join(' ');
  });
  if (window.keys_option == 'hide') {
    window.hidden_keys = window.selected_keys;
  } else {
    window.hidden_keys = $.grep(window.available_keys, function(n,i) { return $.inArray(n, window.selected_keys) == -1; });
  }
  for (var i = 0; i < window.hidden_keys.length; i++) {
    key = window.hidden_keys[i];
    key_css_friendly = key.replace('.', '_');
    body.addClass('hide_' + key_css_friendly);
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

  // Init show hide keys
  initHideShow();

});
