(function() {
	var View = Backbone.View;

	var BaseView = View.extend({
		constructor: function() {
			this.views = [];
			View.apply(this, arguments);
		},
		remove: function() {
			this.clear();
			View.prototype.remove.apply(this, arguments);
		},
		clear: function() {
			_(this.views).each(function(view) {
				if(typeof view.clear === 'function') view.clear();
				view.stopListening();
			});
		}
	});

	app.views.BaseView = BaseView;
}());
