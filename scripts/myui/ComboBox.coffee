define ['jquery', 'cs!myui/Util', 'cs!myui/Autocompleter'], ($, Util, Autocompleter) ->
    eventUtil = $.util.event

    class ComboBox extends Autocompleter
        ###
        # Constructor method.
        ###
        constructor : (options) ->
            @baseInitialize(options)
            @options.minChars ?= 0

        ###
        # Key press handler.
        ###
        _keyPress : (event) ->
            if event.which is eventUtil.KEY_DOWN and !@active
                #event.stopPropagation()
                @changed = false
                @showAll()

        ###
        # Displays ComboBox control.
        ###
        render : (input) ->
            super(input)
            @element.keydown (event) => @_keyPress(event)

        ###
        # Show all elements in the list.
        ###
        showAll : ->
            if !@active
                unless @update
                    @update = $('<div id="'+@id+'_update" class="my-autocompleter-list my-all-round-corners my-drop-shadow"><div class="my-inner-list-container"></div></div>')
                    @_innerListContainer = $('.my-inner-list-container', @update)
                    $(document.body).append(@update)

                @element.focus()
                @element.select()
                @hasFocus = true
                @active = true
                @getAllChoices()
                @_syncScroll(@_getEntry(@index), true) if @index >= 0
            else
                @options.onHide(@element, @update)

        ###
        # Retrieves all choices.
        ###
        getAllChoices : ->
            @updateChoices @all()

        ###
        # Generates a list with all elements.
        ###
        all : ->
            currentValue = $(@element).val()
            result = []
            text = ''
            value = ''
            items = []
            if @options.items
                items = @options.items
            else if @options.url
                parameters = @options.parameters
                if @options.getParameters
                    moreParams = @options.getParameters()
                    for p of moreParams
                        parameters[p] = moreParams[p]

                $.ajax(@options.url, {
                    complete: (response) =>
                        items = @options.items = $.parseJSON(response.responseText)
                    ,
                    dataType : 'json',
                    parameters: parameters,
                    async: false
                })

            listTextPropertyName = @options.listTextPropertyName
            listValuePropertyName = @options.listValuePropertyName
            i = 0
            for item in items
                if typeof(item) is 'object'
                    text = item[listTextPropertyName]
                    value = item[listValuePropertyName]
                else
                    text = item
                    value = item
                i++
                if currentValue is text then @index = i - 1
                result.push('<li id="' + value + '">' + text + '</li>')

            return '<ul>' + result.join('') + '</ul>'

        ###
        # Generates input control.
        ###
        decorate : (element) ->
            width = $(element).width()
            height = $(element).height()
            $(element).wrap('<div></div>') # auto complete container
            $(element).css({width : (width - 25)+'px'})
            container = $(element).parent()
            container.addClass('my-autocompleter')
            container.attr('id', @id + '_container')
            container.css({width : width + 'px', height: height + 'px'})
            comboBoxBtn = $('<div></div>')
            comboBoxBtn.addClass('my-combobox-button gradient')
            container.append(comboBoxBtn)
            comboBoxBtn.on 'click', (event) =>
                @showAll()
                event.stopPropagation()
