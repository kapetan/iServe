(function() {
	var TemplateView = app.views.BaseView.extend({
		render: function() {
			var html = this.template();

			this.$el.remove();
			this.setElement(html);

			return this;
		}
	});

	app.views.TemplateView = TemplateView;
}());
