$(function() {
	app.header = new app.views.ContentView('#header-container');
	app.content = new app.views.ContentView('#main-container');

	Backbone.history.start({ root: '/app', pushState: true });
});
