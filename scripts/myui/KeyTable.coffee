define ['jquery', 'cs!myui/Util'], ($, Util) ->

    eventUtil = $.util.event

    class KeyTable
        constructor : (targetTable, options) ->
            options = $.extend({
                idPrefix : '',
                form : false}, options or {})
            @_tableGrid = null
            if targetTable.columnModel? # Is a TableGrid object?
                @_numberOfRows = targetTable.rows.length
                @_numberOfColumns = targetTable.columnModel.length
                @_tableGrid = targetTable
                @_bodyDiv = $(targetTable.bodyDiv)
                @_targetTable = $(targetTable.bodyTable)
            else
                @_targetTable = $(targetTable) # a normal table
                @_numberOfRows = @_targetTable.find('tbody > tr').length
                @_numberOfColumns = options.numberOfColumns or @_targetTable.find('tbody > tr')[0].cells.length

            @idPrefix = options.idPrefix
            @idPrefix = '#mtgC'+ @_tableGrid._mtgId + '_' if @_tableGrid?

            @_tableBody = @_targetTable.find('tbody') # Cache the tbody node of interest
            @_xCurrentPos = null
            @_yCurrentPos = null
            @_nCurrentFocus = null
            @_nOldFocus = null
            @_topLimit = 0
            # Table grid key navigation handling flags
            @blockKeyCaptureFlg = false

            @_nInput = null
            @_bForm = options.form
            @_bInputFocused = false
            @_sFocusClass = 'focus'
            @_xCurrentPos = 0
            @_yCurrentPos = 0

            ###
            # Variable: event
            # Purpose:  Container for all event application methods
            # Scope:    KeyTable - public
            # Notes:    This object contains all the public methods for adding and removing events - these
            #           are dynamically added later on
            ###
            @events = {remove : {}}

            ###
            # Variable: _oaoEvents
            # Purpose:  Event cache object, one array for each supported event for speed of searching
            # Scope:    KeyTable - private
            ###
            @_eventsCache = {"action": [], "esc": [], "focus": [], "blur": []}

            # Use the template functions to add the event API functions
            for sKey of @_eventsCache
                @events[sKey] = @_insertAddEventTemplate(sKey)
                @events.remove[sKey] = @_insertRemoveEventTemplate(sKey)

            # Loose table focus when click outside the table
            @onClickHandler = (event) =>
                return unless @_nCurrentFocus?
                element = $(event.target)
                blurFlg = true
                blurFlg = false if element.closest(@_targetTable).length > 0
                blurFlg = false if element.closest('my-autocompleter, my-autocompleter-list, my-datepicker-container').length > 0
                if blurFlg
                    @removeFocus(@_nCurrentFocus, true)
                    @releaseKeys()
                    @_nOldFocus = null

            $(document).on 'click', @onClickHandler

            @_tableBody.on 'click', (event) =>
                cell = $(event.target).closest('td')
                if cell isnt @_nCurrentFocus
                    @setFocus(cell)
                    @captureKeys()
                @_eventFire('focus', cell)

            @_tableBody.on 'dblclick', (event) =>
                cell = $(event.target).closest('td')
                @_eventFire('action', cell)

            @onKeyPressHandler = (event) =>
                if @onKeyPress(event)
                    event.stopPropagation()
                    event.preventDefault()

            $(document).on 'keydown', @onKeyPressHandler


        ###
        # Purpose:  Create a function (with closure for sKey) event addition API
        # Returns:  function: - template function
        # Inputs:   string:sKey - type of event to detect
        ###
        _insertAddEventTemplate : (sKey) ->
            ###
            # API function for adding event to cache
            # Notes: This function is (interally) overloaded (in as much as javascript allows for that)
            #        the target cell can be given by either node or coords.
            #
            # Parameters:  1. x - target node to add event for
            #              2. y - callback function to apply
            # or
            #              1. x - x coord. of target cell
            #              2. y - y coord. of target cell
            #              3. z - callback function to apply
            ###
            (x, y, z) =>
                if typeof x is "number" and typeof y is "number" and typeof z is "function"
                    @_addEvent(sKey, @getCellFromCoords(x, y), z)
                else if typeof x is "object" and typeof y is "function"
                    @_addEvent(sKey, x, y)


        ###
        # Purpose:  Create a function (with closure for sKey) event removal API
        # Returns:  function: - template function
        # Inputs:   string:sKey - type of event to detect
        ###
        _insertRemoveEventTemplate : (sKey) ->
            ###
            # API function for removing event from cache
            # Returns: number of events removed
            # Notes: This function is (internally) overloaded (in as much as javascript allows for that)
            #        the target cell can be given by either node or coordinates and the function
            #        to remove is optional
            #
            # Parameters: 1. x - target node to remove event from
            #             2. y - callback function to apply
            # or
            #             1. x - x coordinate. of target cell
            #             2. y - y coordinate. of target cell
            #             3. z - callback function to remove - optional
            ###
            (x, y, z) =>
                if typeof arguments[0] is 'number' and typeof arguments[1] is 'number'
                    if ( typeof arguments[2] is 'function' )
                        @_removeEvent(sKey, @getCellFromCoords(x, y), z)
                    else
                        @_removeEvent(sKey, @getCellFromCoords(x, y))
                else if typeof arguments[0] is 'object'
                    if typeof arguments[1] is 'function'
                        @_removeEvent(sKey, x, y)
                    else
                        @_removeEvent(sKey, x)


        ###
        # Add an event to the internal cache
        #
        # @param eventType type of event to add, given by the available elements in _oaoEvents
        # @param element cell to add event too
        # @param fn callback function for when triggered
        ###
        _addEvent : (eventType, element, fn) ->
            return unless element
            @_eventsCache[eventType].push({
                "cell": element,
                "fn": fn
            })

        ###
        # Removes an event from the event cache
        #
        # @param type type of event to look for
        # @param nTarget target table cell
        # @param fn remove function. If not given all handlers of this type will be removed
        # @return number of matching events removed
        ###
        _removeEvent : (type, cell, fn) ->
            eventsCache = @_eventsCache[type];
            i = 0 # initial index
            len = eventsCache.length
            while (i < len)
                if eventsCache[i]['cell'].is(cell)
                    eventsCache.splice(i, 1)
                    return 1
                i++
            return 0

        ###
        # Handles key events moving the focus from one cell to another
        #
        # @param event key event
        ###
        onKeyPress : (event) ->
            return false unless @blockKeyCaptureFlg
            # If a modifier key is pressed (except shift), ignore the event
            return false if event.metaKey or event.altKey or event.ctrlKey
            x = @_xCurrentPos
            y = @_yCurrentPos
            topLimit = @_topLimit
            # Capture shift+tab to match the left arrow key
            keyCode = if event.which == eventUtil.KEY_TAB and event.shiftKey then -1 else event.which
            while true
                switch keyCode
                    when eventUtil.KEY_RETURN # return
                        @_eventFire 'action', @_nCurrentFocus
                        return false
                    when eventUtil.KEY_ESC # esc
                        if !@_eventFire 'esc', @_nCurrentFocus
                            # Only lose focus if there isn't an escape handler on the cell
                            @blur()
                        return false
                    when -1, eventUtil.KEY_LEFT # left arrow
                        return false if @_bInputFocused
                        if @_xCurrentPos > 0
                            x = @_xCurrentPos - 1
                            y = @_yCurrentPos
                        else if @_yCurrentPos > topLimit
                            x = @_numberOfColumns - 1
                            y = @_yCurrentPos - 1
                        break
                    when eventUtil.KEY_UP # up arrow
                        return false if @_bInputFocused
                        if @_yCurrentPos > topLimit
                            x = @_xCurrentPos
                            y = @_yCurrentPos - 1
                        else
                            return true
                        break
                    when eventUtil.KEY_TAB, eventUtil.KEY_RIGHT # right arrow
                        return false if @_bInputFocused
                        if @_xCurrentPos < @_numberOfColumns - 1
                            x = @_xCurrentPos + 1
                            y = @_yCurrentPos
                        else if @_yCurrentPos < @_numberOfRows - 1
                            x = 0
                            y = @_yCurrentPos + 1
                        break
                    when eventUtil.KEY_DOWN # down arrow
                        return true if @_bInputFocused
                        if @_yCurrentPos < @_numberOfRows - 1
                            x = @_xCurrentPos
                            y = @_yCurrentPos + 1
                        else
                            return false
                        break
                    else # Nothing we are interested in
                        return false
                # end switch
                cell = @getCellFromCoords(x, y)
                if cell != null and cell.css('display') != 'none' and cell.closest('tr').css('display') != 'none'
                    break
                else
                    @_xCurrentPos = x
                    @_yCurrentPos = y
            # end while
            @setFocus(cell)
            @_eventFire 'focus', cell
            return true

        ###
        # Set focus on a cell, and remove from an old cell if needed
        #
        # @param element cell node we want to focus on
        # @param bAutoScroll should we scroll the view port to the display
        ###
        setFocus : (element, bAutoScroll = true) ->
            # If cell already has focus, just ignore this call
            return if @_nCurrentFocus? and @_nCurrentFocus.is(element)
            # Remove old css focus class (with blur event if needed)
            @removeFocus(@_nCurrentFocus, false) if @_nCurrentFocus?
            # Add the focus css class to highlight the focused cell
            element.addClass(@_sFocusClass)
            element.closest('tr').addClass(@_sFocusClass)
            # Cache the information that we are interested in
            @_nOldFocus = @_nCurrentFocus
            @_nCurrentFocus = element
            coords = @getCoordsFromCell(element)
            @_xCurrentPos = coords[0]
            @_yCurrentPos = coords[1]
            if bAutoScroll and @_bodyDiv
                # Scroll the viewport such that the new cell is fully visible in the
                # rendered window
                viewportHeight = @_bodyDiv[0].clientHeight
                viewportWidth = @_bodyDiv[0].clientWidth

                scrollTop = @_bodyDiv.scrollTop()
                scrollLeft = @_bodyDiv.scrollLeft()

                height = element.outerHeight()
                width = element.outerWidth()
                pos = @getPosition(element)

                # Correct viewport positioning for vertical scrolling
                if pos[1]+height > scrollTop+viewportHeight
                    # Displayed element if off the bottom of the viewport
                    @setScrollTop(pos[1]+height - viewportHeight)
                else if pos[1] < scrollTop
                    # Displayed element if off the top of the viewport
                    @setScrollTop(pos[1])

                # Correct viewport positioning for horizontal scrolling
                if pos[0] + width > scrollLeft + viewportWidth
                    # Displayed element is off the bottom of the viewport
                    @setScrollLeft(pos[0] + width - viewportWidth)
                else if pos[0] < scrollLeft
                    # Displayed element if off the Left of the viewport
                    @setScrollLeft(pos[0])

        ###
        # Set the vertical scrolling position
        # @param iPos scroll top position
        ###
        setScrollTop : (iPos)	->
            @_bodyDiv.scrollTop(iPos)

        ###
        # Set the horizontal scrolling position
        # @param iPos scroll left position
        ###
        setScrollLeft : (iPos) ->
            @_bodyDiv.scrollLeft(iPos)

        ###
        # Look thought the events cache and fire off the event of interest
        # Notes: It might be more efficient to return after the first event has been triggered,
        #        but that would mean that only one function of a particular type can be
        #        subscribed to a particular node
        #
        # @param sType type of event to look for
        # @param nTarget target table cell
        # @return  number of events fired
        ###
        _eventFire: (eventType, cell) ->
            eventsCache = @_eventsCache[eventType]
            for eventElement in eventsCache
                if eventElement['cell'].is(cell)
                    eventElement['fn'](cell)
                    return true
            return false

        ###
        # Blur focus from the whole table
        ###
        blur : ->
            #return unless @_nCurrentFocus
            #@removeFocus(@_nCurrentFocus, onlyCellFlg)
            #@xCurrentPos = null
            #@yCurrentPos = null
            #@_nCurrentFocus = null
            #@releaseKeys()
            return

        ###
        # Removes focus from a cell and fire any blur events which are attached
        # @param element cell of interest
        ###
        removeFocus : (element, onlyCellFlg = true) ->
            return unless element
            element.removeClass(@_sFocusClass)
            element.closest('tr').removeClass(@_sFocusClass) unless onlyCellFlg
            @_eventFire("blur", element)

        ###
        # Get the position of an object on the rendered page
        # @param obj element of interest
        # @return the element position [left, right]
        ###
        getPosition : (element) ->
            left = 0
            top = 0
            if element.position()
                left = element.position().left
                top = element.position().top
            return [left, top]

        ###
        # Calculates the x and y position in a table from a TD cell
        #
        # @param element cell of interest
        # @return [x, y] position of the element
        ###
        getCoordsFromCell : (element) ->
            id = $(element).attr('id')
            return null unless id?
            match = id.match(/c(\d*?)r(\-?\d*?)$/)
            return [
                parseInt(match[1]),
                parseInt(match[2])
            ]

        ###
        # Calculates the target TD cell from x and y coordinates
        # @param x coordinate
        # @param y coordinate
        # @return TD target
        ###
        getCellFromCoords : (x, y) ->
            element = $(@idPrefix + 'c' + x + 'r' + y, @_tableBody)
            return null if element.length == 0
            return element
            # return @_targetTable.rows[y].cells[x] # <-- this sadly doesn't work

        ###
        # Start capturing key events for this table
        ###
        captureKeys : ->
            @blockKeyCaptureFlg = true

        ###
        # Stop capturing key events for this table
        ###
        releaseKeys : ->
            @blockKeyCaptureFlg = false

        ###
        # Sets the top limit of the grid
        #
        # @param topLimit the the table grid top limit
        ###
        setTopLimit : (topLimit) ->
            @_topLimit = topLimit

        ###
        # Sets the number of rows
        # @param numberOfRows the table grid number of rows
        ###
        setNumberOfRows : (numberOfRows) ->
            @_numberOfRows = numberOfRows

        stop : ->
            $(document).unbind('keydown', @onKeyPressHandler)
            $(document).unbind('click', @onClickHandler)
