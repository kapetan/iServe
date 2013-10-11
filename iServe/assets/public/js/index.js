$(function() {
	app.header = new app.views.ContentView('#header-container');
	app.content = new app.views.ContentView('#main-container');

	Backbone.history.start({ pushState: true });

	$(document).on('click', 'a:not([data-bypass])', function (e) {
		var href = $(this).attr('href');
		var protocol = this.protocol + '//';

		if (href.slice(protocol.length) !== protocol) {
			e.preventDefault();
			app.router.navigate(href, { trigger: true });
		}
	});
});
