
var $window = $(window)
var $body   = $(document.body)

var navHeight = $('.navbar').outerHeight(true)

$body.scrollspy({
    target: '.bs-sidebar',
    offset: navHeight
})

$window.on('load', function () {
    $body.scrollspy('refresh')
})

$('.bs-sidebar').affix({
    offset: {
	top: function() {
	    return (this.top = $('.bs-header').outerHeight(true))
	},
	bottom: function () {
            return (this.bottom = $('#footer').outerHeight(true))
	}
    }
})
