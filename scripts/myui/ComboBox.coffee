define ['jquery', 'cs!myui/Autocompleter'], ($, Autocompleter) ->
    class ComboBox extends Autocompleter
        constructor : (options) ->
            @baseInitialize(options)
            @options.minChars ?= 0
            @options.all = (instance) ->
                currentValue = $(instance.element).val()
                result = []
                text = ''
                value = ''
                items = []
                if instance.options.items
                    items = instance.options.items;
                else if instance.options.url
                    parameters = instance.options.parameters
                    if instance.options.getParameters
                        moreParams = instance.options.getParameters()
                        for p of moreParams
                            parameters[p] = moreParams[p]

                    $.ajax(@options.url, {
                        complete: (response) =>
                            items = instance.options.items = $.parseJSON(response.responseText)
                        ,
                        dataType : 'json',
                        parameters: parameters
                    })

                listTextPropertyName = instance.options.listTextPropertyName
                listValuePropertyName = instance.options.listValuePropertyName
                i = 0
                for item in items
                    if typeof(item) is 'object'
                        text = item[listTextPropertyName]
                        value = item[listValuePropertyName]
                    else
                        text = item
                        value = item
                    i++
                    if currentValue is text then instance.index = i
                    result.push('<li id="' + value + '">' + text + '</li>')

                return '<ul>' + result.join('') + '</ul>';

    _keyPress : (event) ->
        if event.which is 40 && !@active
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
            if @index >= 0
                @_syncScroll(@_getEntry(@index), true)
        else
            @options.onHide(@element, @update)

    getAllChoices : ->
        @updateChoices(@options.all(@))

    decorate : (element) ->
        width = $(element).width()
        height = $(element).height()
        $(element).wrap('div') # auto complete container
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
