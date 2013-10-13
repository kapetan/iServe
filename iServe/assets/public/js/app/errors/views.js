(function() {
	var ErrorView = app.views.TemplateView.extend({
		template: function() {
			var url = window.location.toString();
			var ua = window.navigator.userAgent;

			return app.templates['error.html']({ error: this.options.error, url: url, userAgent: ua });
		}
	});

	app.views.ErrorView = ErrorView;
}());
