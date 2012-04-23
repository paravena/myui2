define ['jquery', 'cs!myui/Autocompleter'], ($, Autocompleter) ->
    class ComboBox extends Autocompleter
        constructor : (options) ->
            @baseInitialize(options)
            @options.minChars ?= 0

        _keyPress : (event) ->
            if event.which is 40 and !@active
                event.stopPropagation()
                @changed = false
                @showAll()

        render : (input) ->
            super(input)
            @element.keydown (event) => @_keyPress(event)


        showAll : ->
            if !@active
                unless @update
                    $(document.body).append('<div id="'+@id+'_update" class="my-autocompleter-list shadow"></div>')
                    @update = $('#' + @id+'_update')
                @element.focus()
                @element.select()
                @hasFocus = true
                @active = true
                @getAllChoices()
                @_syncScroll(@_getEntry(@index), true) if @index >= 0
            else
                @options.onHide(@element, @update)

        getAllChoices : ->
            @updateChoices @all()

        all : ->
            console.log @
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
                    parameters: parameters
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
                if currentValue is text then @index = i
                result.push('<li id="' + value + '">' + text + '</li>')

            return '<ul>' + result.join('') + '</ul>'

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
            comboBoxBtn.click (event) =>
                @showAll()
                event.stopPropagation()
