define ['jquery'], ($) ->
		class TextField
				constructor : (options = {}) ->
						@baseInitialiaze(options)
						if options.input
								@render options.input
								@decorate $(options.input)

				baseInitialize : (options) ->
						@tableGrid = undefined
						@options = options

