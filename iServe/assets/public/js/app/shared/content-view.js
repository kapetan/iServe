(function() {
	var ContentView = function(elem) {
		this.$el = $(elem);
		this.el = this.$el.get(0);

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
	ContentView.prototype.clear = function() {
		if(this.view) this.view.remove();
		this.$el.empty();
	};
	ContentView.prototype.remove = function() {
		if(this.view) this.view.remove();
		this.$el.remove();
	};

	app.views.ContentView = ContentView;
}());
