define ['jquery', 'cs!myui/Util', 'cs!myui/TextField'], ($, Util, TextField) ->
    eventUtil = $.util.event

    class Autocompleter extends TextField
        ###
        # Constructor method.
        ###
        constructor : (options) ->
            @baseInitialize(options)

        ###
        # Base initializer.
        ###
        baseInitialize : (options) ->
            super(options)
            @element = $(options.input)
            @hasFocus = false
            @changed = false
            @active = false
            @index = 0
            @entryCount = 0

            @options = $.extend({
                items: null,
                listId: null,
                tokens: [],
                frequency: 0.4,
                minChars: 2,
                url: null,
                parameters: {},
                finderParamName: 'find',
                listTextPropertyName: 'text',
                listValuePropertyName: 'value',
                height: null,
                indicator: null,
                autoSelect: false,
                choices: 10,
                partialSearch : true,
                partialChars : 1,
                ignoreCase: true,
                fullSearch: false,
                getParameters: null
            }, options or {})

            unless @options.decorate
                @options.decorate = => @decorate(@element)

            unless @options.onShow
                @options.onShow = (element, update) =>
                    p = $(element).offset()
                    vh = $(window).height() #view port height
                    vst = $(window).scrollTop() # view port scrolling top
                    rh = vh + vst - p.top - $(element).outerHeight() #remaining height
                    uh = (@entryCount * 22) + 6
                    offsetTop = p.top
                    offsetLeft = p.left
                    topPos = $(element).outerHeight() + offsetTop + 2
                    elementWidth = $(element).closest('div').width() - 2
                    leftPos = offsetLeft
                    pointerCssClass = 'my-arrow-up-pointer'
                    if (rh >= (p.top - vst))  # down
                        if (uh > rh) then uh = rh - 10
                        update.css({
                            top : topPos + 'px',
                            left : leftPos + 'px',
                            width : elementWidth + 'px',
                            height: uh + 'px'
                        }).addClass(pointerCssClass)
                    else  # above
                        if (uh > (p.top - vst))
                            uh = p.top - vst - 10
                            topPos = p.top - (uh + 4)
                            pointerCssClass = 'my-arrow-down-pointer'
                        else if (uh > rh)
                            topPos = p.top - (uh + 4)
                            pointerCssClass = 'my-arrow-down-pointer'

                        update.css({
                            top : topPos + 'px',
                            left : leftPos + 'px',
                            width : elementWidth + 'px',
                            height: uh + 'px'
                        }).addClass(pointerCssClass)
                    $('.my-inner-list-container', update).css('height', uh + 'px')
                    $('.my-inner-list-container', update).css('width', elementWidth + 'px')
                    $(update).show()

            unless @options.onHide
                @options.onHide = (element, update) =>
                    $(update).hide()
                    @hasFocus = false
                    @active = false

            unless @options.selector
                @options.selector = =>
                    result = [] # Beginning matches
                    partial = [] # Inside matches
                    entry = @_getToken()
                    items = @options.items
                    listTextPropertyName = @options.listTextPropertyName
                    listValuePropertyName = @options.listValuePropertyName
                    text = ''
                    value = ''
                    i = 0

                    while i < items.length and result.length < @options.choices
                        if typeof(items[i]) is 'object'
                            text = items[i][listTextPropertyName]
                            value = items[i][listValuePropertyName]
                        else
                            text = items[i]
                            value = items[i]

                        if @options.ignoreCase
                            foundPos = text.toLowerCase().indexOf(entry.toLowerCase())
                        else
                            foundPos = text.indexOf(entry)

                        while foundPos isnt -1
                            if foundPos is 0 and text.length isnt entry.length
                                result.push('<li id="' + value + '"><strong>' + text.substr(0, entry.length) + '</strong>' + text.substr(entry.length) + '</li>')
                                break
                            else if entry.length >= @options.partialChars and @options.partialSearch and foundPos isnt -1
                                if @options.fullSearch or /\s/.test(text.substr(foundPos - 1, 1))
                                    partial.push('<li>' + text.substr(0, foundPos) + '<strong>' + text.substr(foundPos, entry.length) + '</strong>' + text.substr(foundPos + entry.length) + '</li>')
                                    break
                            if @options.ignoreCase
                                foundPos = text.toLowerCase().indexOf(entry.toLowerCase(), foundPos + 1)
                            else
                                foundPos = text.indexOf(entry, foundPos + 1)
                        #end while
                        i++
                    #end while
                    if partial.length
                        result = result.concat(partial.slice(0, @options.choices - result.length))
                    return "<ul>" + result.join('') + "</ul>"

            if typeof(@options.tokens) is 'string'
                @options.tokens = new Array(@options.tokens)

            # Force carriage returns as token delimiters anyway
            unless '\n' in @options.tokens
                @options.tokens.push '\n'

            @observer = null
            @render(@element) if @element?

        ###
        # Displays autocompleter control.
        ###
        render : (input) ->
            super(input)
            @element = $(input)
            @id = @element.attr('id')
            @oldElementValue = @element.val()
            @options.paramName ?= @element.name
            @element.attr('autocomplete', 'off')
            @options.decorate()
            @container = $('#' + @id + '_container')
            $(document).on 'click', (event) => @_onBlur(event)
            @element.on 'keydown', (event) => @_onKeyPress(event)

        ###
        # Displays autocompleter control.
        ###
        show : ->
            @options.onShow @element, @update

        ###
        # On focus handler.
        ###
        onFocus : (event) ->
            super(event)
            @tokenBounds = null

        ###
        # Returns item elements.
        ###
        getItems : ->
            return @options.items

        ###
        # Reset autocomplete list.
        ###
        reset : ->
            # @options.items = null TODO check why is causing a problem when rendering the grid control

        ###
        # Retrieves updated choice list.
        ###
        getUpdatedChoices : ->
            unless @update
                $(document.body).append('<div id="'+@id+'_update" class="my-autocompleter-list my-all-round-corners my-drop-shadow"><div class="my-inner-list-container"></div></div>')
                @update = $('#' + @id + '_update')
                @_innerListContainer = $('.my-inner-list-container', @update)

            if @options.url
                parameters = @options.parameters
                parameters[@options.finderParamName] = @_getToken()
                if @options.getParameters
                    moreParams = @options.getParameters()
                    for p of moreParams
                        parameters[p] = moreParams[p]

                @startIndicator()
                $.ajax(@options.url, {
                    complete: (response) =>
                        @options.items = $.parseJSON(response.responseText)
                        @_stopIndicator()
                        @updateChoices @options.selector()
                    ,
                    dataType : 'json',
                    parameters: parameters
                })
            else
                @updateChoices @options.selector()

        ###
        # On blur handler.
        ###
        _onBlur : (event) ->
            return unless @active
            target = $(event.target)
            ancestor = @container
            blurFlg = true
            blurFlg = false if target.closest(ancestor).size() > 0 # is descendant of ?
            if blurFlg
                @hide()
                @hasFocus = false
                @active = false

        ###
        # Decorates autocompleter control.
        ###
        decorate : (element) ->
            width = $(element).width()
            height = $(element).height()
            $(element).css({width: (width - 8) + 'px'})
            $(element).wrap('<div></div>') # auto complete container
            container = $(element).closest('div') # parent
            container.addClass('my-autocompleter')
            container.attr('id', @id + '_container')
            container.css({'width' : width + 'px', 'height': height + 'px'})

        ###
        # Hide choice list.
        ###
        hide : ->
            @_stopIndicator()
            if @update
                @update.remove()
                @active = false
                @hasFocus = false
                @update = null

        ###
        # Displays spinner indicator.
        ###
        startIndicator : ->
            $(@options.indicator).show() if @options.indicator?

        ###
        # Hides spinner indicator.
        ###
        _stopIndicator : ->
            $(@options.indicator).hide() if @options.indicator?

        ###
        # On keypress handler.
        ###
        _onKeyPress: (event) ->
            if @active
                switch event.keyCode
                    when eventUtil.KEY_TAB, eventUtil.KEY_RETURN
                        @_selectEntry()
                        event.stopPropagation()
                    when eventUtil.KEY_ESC
                        @hide()
                        @active = false
                        event.stopPropagation()
                        return true
                    when eventUtil.KEY_LEFT, eventUtil.KEY_RIGHT
                        return true
                    when eventUtil.KEY_UP
                        @_markPrevious()
                        @_renderList()
                        event.stopPropagation()
                        return true
                    when eventUtil.KEY_DOWN
                        @_markNext()
                        @_renderList()
                        event.stopPropagation()
                        return true
            else if event.keyCode is eventUtil.KEY_TAB or
                    event.keyCode is eventUtil.KEY_RETURN or
                    event.keyCode is eventUtil.KEY_DOWN or
                    ($.browser.WebKit and event.keyCode is 0)
                return true

            @changed = true
            @hasFocus = true

            clearTimeout @observer if @observe?
            @observer = setTimeout(( => @onObserverEvent()), @options.frequency * 1000)
            return true

        ###
        # Activates autocompleter control.
        ###
        activate : ->
            @changed = false
            @hasFocus = true
            @getUpdatedChoices()

        ###
        # On hover handler.
        ###
        onHover : (event) ->
            element = $(event.target).closest('LI')[0]
            if @index isnt $(element).data('autocompleteIndex')
                @index = $(element).data('autocompleteIndex')
                @_renderList()

        ###
        # On click handler.
        ###
        onClick : (event) ->
            element = $(event.target).closest('LI')[0]
            @index = $(element).data('autocompleteIndex')
            @_selectEntry()
            @hide()

        ###
        # Displays choice list.
        ###
        _renderList : ->
            if @entryCount > 0
                for i in [0...@entryCount]
                    if @index is i
                        $(@_getEntry(i)).addClass('selected')
                    else
                        $(@_getEntry(i)).removeClass('selected')
                if @hasFocus
                    @show()
                    @active = true
            else
                @active = false
                @hide()

        ###
        # Returns entry by a given index.
        ###
        _getEntry : (index) ->
            return $('LI', @update)[index]

        ###
        # Highlight previous item choice.
        ###
        _markPrevious : ->
            if @index > 0
                @index--
            else
                @index = @entryCount - 1
            @_syncScroll(@_getEntry(@index), false)

        ###
        # Highlight next item choice.
        ###
        _markNext : ->
            if @index < @entryCount - 1
                @index++
            else
                @index = 0
            @_syncScroll(@_getEntry(@index), true)

        ###
        # Synchronizes scrolling.
        ###
        _syncScroll : (entry, bottomFlg) ->
            return unless entry?
            updateHeight = @_innerListContainer.height()
            scrollTop = @_innerListContainer.scrollTop()
            topPos = $(entry).position().top
            if topPos > scrollTop and topPos < (scrollTop + updateHeight - 10)
                return
            unless bottomFlg
                @_innerListContainer.scrollTop(topPos)
            else
                @_innerListContainer.scrollTop(topPos - (updateHeight - $(entry).height() - 5))

        ###
        # Returns selected item choice.
        ###
        getCurrentEntry : ->
            return @_getEntry(@index)

        ###
        # Highlight selected item choice.
        ###
        _selectEntry : ->
            @_updateElement(@getCurrentEntry())

        ###
        # Returns value.
        ###
        getValue : ->
            return @oldElementValue

        ###
        # Updates element.
        ###
        _updateElement : (selectedElement) ->
            # if an updateElement method is provided
            if @options.updateElement
                @options.updateElement(selectedElement)
                return

            value = $(selectedElement).not('informal').text()

            bounds = @_getTokenBounds()

            if bounds[0] isnt -1
                newValue = @element.val().substr(0, bounds[0])
                whitespace = @element.val().substr(bounds[0]).match(/^\s+/)
                if (whitespace)
                    newValue += whitespace[0]
                @element.val(newValue + value + @element.val().substr(bounds[1]))
            else
                @element.val(value)

            @oldElementValue = @element.val()
            @element.val(value)
            @oldElementValue = @element.val()
            @validate()
            @element.focus()
            if (@options.afterUpdate)
                @options.afterUpdate(@element, selectedElement)

        ###
        # Updates choice list.
        ###
        updateChoices : (choices) ->
            if !@changed and @hasFocus
                $('.my-inner-list-container', @update).html(choices)
                i = 0
                entries = $('LI', @update)
                @entryCount = entries.length
                @addObservers(entries)

                @_stopIndicator()
                if @index is undefined then @index = 0

                if @entryCount is 1 and @options.autoSelect
                    @_selectEntry()
                    @hide()
                else
                    @_renderList()

        ###
        # Add event observers.
        ###
        addObservers : (entries) ->
            entries.mouseover (event) => @onHover(event)
            entries.on 'click', (event) => @onClick(event)
            entries.each (index, entry) ->
                $(entry).data('autocompleteIndex', index)

        ###
        # On observer event handler.
        ###
        onObserverEvent : ->
            @changed = false
            @tokenBounds = null
            if @_getToken().length >= @options.minChars
                @getUpdatedChoices()
            else
                @active = false
                @hide()

            @oldElementValue = @element.val()

        ###
        # Returns token.
        ###
        _getToken : ->
            bounds = @_getTokenBounds()
            return $.trim(@element.val().substring(bounds[0], bounds[1]))

        ###
        # Returns am array containing the indexes
        # that delimits the entered text.
        ###
        _getTokenBounds : ->
            return @tokenBounds if @tokenBounds
            value = @element.val()
            if $.trim(value) is '' then return [-1, 0]
            diff = @getFirstDifferencePos(value, @oldElementValue)
            offset = if diff is @oldElementValue.length then 1 else 0
            prevTokenPos = -1
            nextTokenPos = value.length
            index = 0
            l = @options.tokens.length
            while (index < l)
                tp = value.lastIndexOf(@options.tokens[index], diff + offset - 1)
                if tp > prevTokenPos then prevTokenPos = tp
                tp = value.indexOf(@options.tokens[index], diff + offset)
                if -1 != tp and tp < nextTokenPos then nextTokenPos = tp
                ++index
            return (@tokenBounds = [prevTokenPos + 1, nextTokenPos])

        ###
        # Returns first position where a character is
        # found different than the current entered text.
        ###
        getFirstDifferencePos : (newS, oldS) ->
            boundary = Math.min(newS.length, oldS.length)
            for index in [0...boundary] #TODO check this
                if newS[index] isnt oldS[index]
                    return index
            return boundary

        ###
        # Returns selected value.
        ###
        getSelectedValue : (text) ->
            items = @options.items
            result = text
            # only applicable when items is an array of objects
            if items[0] instanceof Object
                listTextPropertyName = @options.listTextPropertyName
                listValuePropertyName = @options.listValuePropertyName
                for item in items
                    if item[listTextPropertyName] == text
                        result = item[listValuePropertyName]
                        break
            return result
