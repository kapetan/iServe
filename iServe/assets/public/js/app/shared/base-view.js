(function() {
	var View = Backbone.View;

	var BaseView = View.extend({
		constructor: function() {
			this.subviews = [];
			View.apply(this, arguments);
		},
		remove: function() {
			this.clear();
			View.prototype.remove.apply(this, arguments);

			this.trigger('remove');
		},
		clear: function() {
			_(this.subviews).each(function(view) {
				if(typeof view.clear === 'function') view.clear();
				view.stopListening();
			});

			this.trigger('clear');
		}
	});

	_(BaseView.prototype).extend(Backbone.Events);

	app.views.BaseView = BaseView;
}());
