define ['jquery', 'cs!js/myui/TextField'], ($, TextField) ->
    class BrowseInput extends TextField
        constructor : (options) -> 
            @baseInitialize(options)
            @afterUpdate = options.afterUpdate or null
            @onClick = options.onClick or null
        
        render : (input) ->
            super(input)
            @targetElement = input
            @decorate(@targetElement) if @targetElement?

        decorate : (element) ->
            width = $(element).width()
            height = $(element).height()
            $(element).wrap('<div></div>')
            $(element).css('width', (width - 29)+'px')
            container = element.parent()
            container.attr('id', @id + '_container')
            container.css({'width' : width + 'px', 'height' : height + 'px'})
            browseBtn = $('<div></div>').addClass('my-tablegrid-browse-button').appendTo(container)
            onClickFlg = false;
            browseBtn.on 'click', (event) =>
                @onClick() if @onClick
                event.stopPropagation() # TODO check this maybe is not necessary
                onClickFlg = true
            # TODO this is weird require further revision
            @afterUpdateCallback = (element, value) =>
                @afterUpdate(element, value) if @afterUpdate? and !onClickFlg
                onClickFlg = false
