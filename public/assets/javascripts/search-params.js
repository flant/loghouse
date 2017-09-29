function SearchParams(btn_selector) {

  function getParams (btn_selector) {
    var objects = {};
    $(btn_selector).each(function() {
      var popover_selector = $(this).data('target');
      objects[popover_selector] = (new SearchParam($(popover_selector)));
    });
    return objects;
  }

  this.btn_selector = btn_selector;
  this.params = getParams(btn_selector);
  this.initEvents();
}

SearchParams.prototype.initEvents = function() {
  var search_params = this;
  $.each(this.params, function(key, param) {
    param.btn.on('click', function() {
      if (param.is_open) {
        param.close();
      } else {
        search_params.closeAll();
        param.open();
      }
    });
  });
}

SearchParams.prototype.closeAll = function() {
  $.each(this.params, function(key, param) {
    param.close();
  });
}

function SearchParam(selector) {
  this.popover = $(selector);
  this.btn = $('[data-target="#' + this.popover.attr('id') + '"]');
  this.is_open = false;
  this._popover_active_class = 'search-params-popover_active';
  this._btn_active_class = 'search-params-popover_active';
}

SearchParam.prototype.close = function() {
  this.popover.removeClass(this._popover_active_class);
  this.btn.removeClass(this._btn_active_class);
  this.is_open = false;
}

SearchParam.prototype.toggle = function() {
  this.popover.toggleClass(this._popover_active_class);
  this.btn.toggleClass(this._btn_active_class);
  this.is_open = !this.is_open;
}

SearchParam.prototype.open = function() {
  this.popover.addClass(this._popover_active_class);
  this.btn.addClass(this._btn_active_class);
  this.is_open = true;
}
