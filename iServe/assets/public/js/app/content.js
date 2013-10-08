(function() {
	var ContentView = function(elem) {
		this.$el = $(elem);
		this.view = null;
	};
	ContentView.prototype.render = function(view) {
		if(this.view) this.view.remove();

		this.view = null;

		if(view instanceof Backbone.View) {
			this.view = view;
			view = view.el;
		}

		this.$el.html(view);
	};

	app.views.ContentView = ContentView;
}());
