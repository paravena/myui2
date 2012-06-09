define ['jquery', 'cs!myui/Util', 'cs!myui/TableGrid'], ($, Util, TableGrid) ->

    eventUtil = $.util.event

    class KeyTable
        constructor : (targetTable, options) ->
            options = $.extend({
                idPrefix : '',
                form : false}, options or {})

            if targetTable instanceof TableGrid
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
            @idPrefix = '#mtgC'+ @_tableGrid._mtgId + '-' if @_tableGrid

            @nBody = @_targetTable.find('tbody') # Cache the tbody node of interest
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
            @event = {remove : {}}

            ###
            # Variable: _oaoEvents
            # Purpose:  Event cache object, one array for each supported event for speed of searching
            # Scope:    KeyTable - private
            ###
            @_oaoEvents = {"action": [], "esc": [], "focus": [], "blur": []}

            # Use the template functions to add the event API functions
            for sKey of @_oaoEvents
                @event[sKey] = @insertAddEventTemplate(sKey)
                @event.remove[sKey] = @insertRemoveEventTemplate(sKey)

            # Loose table focus when click outside the table
            @onClickHandler = (event) =>
                unless @_nCurrentFocus then return
                element = $(event.target)
                blurFlg = true
                blurFlg = false if element.closest(@_targetTable).length > 0
                blurFlg = false if element.closest('my-autocompleter, my-autocompleter-list, my-datepicker-container').length > 0
                if blurFlg
                    @removeFocus(@_nCurrentFocus, true)
                    @releaseKeys()
                    @_nOldFocus = null

            $(document).click @onClickHandler

            @addMouseBehavior() if targetTable instanceof TableGrid

            @onKeyPressHandler = (event) =>
                result = @onKeyPress(event)
                event.stopPropagation() # unless result
                event.preventDefault()

            $(document).keydown @onKeyPressHandler

        addMouseBehavior : ->
            tableGrid = @_tableGrid
            renderedRows = tableGrid.renderedRows
            renderedRowsAllowed = tableGrid.renderedRowsAllowed
            beginAtRow = renderedRows - renderedRowsAllowed
            beginAtRow = 0 if beginAtRow < 0
            @addMouseBehaviorToRow(j) for j in [beginAtRow...renderedRows]

        addMouseBehaviorToRow : (y) ->
            for i in [0...@_numberOfColumns]
                element = @getCellFromCoords(i, y)
                f_click = (event) =>
                    @onClick(event)
                    @eventFire('focus', element)

                element.click f_click

                f_dblclick = (event) =>
                    @eventFire('action', element)

                element.dblclick f_dblclick

        ###
        # Purpose:  Create a function (with closure for sKey) event addition API
        # Returns:  function: - template function
        # Inputs:   string:sKey - type of event to detect
        ###
        insertAddEventTemplate : (sKey) ->
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
                    @addEvent(sKey, @getCellFromCoords(x, y), z)
                else if typeof x is "object" and typeof y is "function"
                    @addEvent(sKey, x, y)


        ###
        # Purpose:  Create a function (with closure for sKey) event removal API
        # Returns:  function: - template function
        # Inputs:   string:sKey - type of event to detect
        ###
        insertRemoveEventTemplate : (sKey) ->
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
                        @removeEvent(sKey, @getCellFromCoords(x, y), z)
                    else
                        @removeEvent(sKey, @getCellFromCoords(x, y))
                else if typeof arguments[0] is 'object'
                    if typeof arguments[1] is 'function'
                        @removeEvent(sKey, x, y)
                    else
                        @removeEvent(sKey, x)


        ###
        # Add an event to the internal cache
        #
        # @param eventType type of event to add, given by the available elements in _oaoEvents
        # @param element cell to add event too
        # @param fn callback function for when triggered
        ###
        addEvent : (eventType, element, fn) ->
            return unless element
            @_oaoEvents[eventType].push({
                "nCell": element,
                "fn": fn
            })

        ###
        # Removes an event from the event cache
        #
        # @param sType type of event to look for
        # @param nTarget target table cell
        # @param fn remove function. If not given all handlers of this type will be removed
        # @return number of matching events removed
        ###
        removeEvent : (sType, nTarget, fn) ->
            iCorrector = 0
            i = 0
            iLen = @_oaoEvents[sType].length
            while (i < iLen - iCorrector)
                if typeof fn isnt 'undefined'
                    if @_oaoEvents[sType][i - iCorrector].nCell is nTarget and @_oaoEvents[sType][i - iCorrector].fn is fn
                        @_oaoEvents[sType].splice(i - iCorrector, 1)
                        iCorrector++
                else
                    if @_oaoEvents[sType][i].nCell is nTarget
                        @_oaoEvents[sType].splice(i, 1)
                        return 1
                i++
            return iCorrector

        ###
        # Handles key events moving the focus from one cell to another
        #
        # @param event key event
        ###
        onKeyPress : (event) ->
            return false unless @blockKeyCaptureFlg
            # If a modifier key is pressed (except shift), ignore the event
            return false if event.metaKey || event.altKey || event.ctrlKey
            x = @_xCurrentPos
            y = @_yCurrentPos
            topLimit = @_topLimit
            # Capture shift+tab to match the left arrow key
            keyCode = if event.which == eventUtil.KEY_TAB and event.shiftKey then -1 else event.which
            cell = null
            while(true)
                switch keyCode
                    when eventUtil.KEY_RETURN # return
                        @eventFire('action', @_nCurrentFocus)
                        return true
                    when Event.KEY_ESC # esc
                        if !@eventFire('esc', @_nCurrentFocus)
                            # Only lose focus if there isn't an escape handler on the cell
                            @blur()
                        return false
                    when -1, eventUtil.KEY_LEFT # left arrow
                        return true if @_bInputFocused
                        if @_xCurrentPos > 0
                            x = @_xCurrentPos - 1
                            y = @_yCurrentPos
                        else if @_yCurrentPos > topLimit
                            x = @_numberOfColumns - 1
                            y = @_yCurrentPos - 1
                        else
                            # at start of table
                            if keyCode is -1 and @_bForm
                                # If we are in a form, return focus to the 'input' element such that tabbing will
                                # follow correctly in the browser
                                @_bInputFocused = true
                                @_nInput.focus()
                                # This timeout is a little nasty - but IE appears to have some asynchronous behaviour for
                                # focus
                                callback = () => @_bInputFocused = false
                                setTimeout(callback, 0)
                                @blockKeyCaptureFlg = false
                                @blur()
                                return true
                            else
                                return false
                        break
                    when eventUtil.KEY_UP # up arrow
                        return true if @_bInputFocused
                        if @_yCurrentPos > topLimit
                            x = @_xCurrentPos
                            y = @_yCurrentPos - 1
                        else
                            return false
                        break
                    when eventUtil.KEY_TAB, eventUtil.KEY_RIGHT # right arrow
                        return true if @_bInputFocused
                        if @_xCurrentPos < @_numberOfColumns - 1
                            x = @_xCurrentPos + 1
                            y = @_yCurrentPos
                        else if @_yCurrentPos < @_numberOfRows - 1
                            x = 0
                            y = @_yCurrentPos + 1
                        else
                            # at end of table
                            if keyCode is eventUtil.KEY_TAB and @_bForm
                                # If we are in a form, return focus to the 'input' element such that tabbing will
                                # follow correctly in the browser
                                @_bInputFocused = true
                                @_nInput.focus()
                                # This timeout is a little nasty - but IE appears to have some asynchronous behaviour for
                                # focus
                                callback = () => @_bInputFocused = false
                                setTimeout(callback, 0)
                                @blockKeyCaptureFlg = false
                                @blur()
                                return true
                            else
                                return false
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
                        return true
                # end switch
                cell = @getCellFromCoords(x, y)
                if cell != null && cell.css('display') != 'none' and cell.closest('tr').css('display') != 'none'
                    break
                else
                    @_xCurrentPos = x
                    @_yCurrentPos = y
            # end while
            @setFocus(cell)
            @eventFire("focus", cell)
            return true

        ###
        # Set focus on a cell, and remove from an old cell if needed
        #
        # @param element cell node we want to focus on
        # @param bAutoScroll should we scroll the view port to the display
        ###
        setFocus : (element, bAutoScroll = true) ->
            # If cell already has focus, just ignore this call
            return if @_nCurrentFocus == element
            # Remove old css focus class (with blur event if needed)
            @removeFocus(@_nCurrentFocus) if @_nCurrentFocus
            # Add the focus css class to highlight the focused cell
            element.addClass(@_sFocusClass)
            element.parent('tr').addClass(@_sFocusClass) if element.closest('tr')
            # Cache the information that we are interested in
            @_nOldFocus = @_nCurrentFocus
            @_nCurrentFocus = element
            coords = @getCoordsFromCell(element)
            @_xCurrentPos = coords[0]
            @_yCurrentPos = coords[1]
            if bAutoScroll and @_bodyDiv
                # Scroll the viewport such that the new cell is fully visible in the
                # rendered window
                iViewportHeight = @_bodyDiv.clientHeight
                iViewportWidth = @_bodyDiv.clientWidth

                iScrollTop = @_bodyDiv.scrollTop()
                iScrollLeft = @_bodyDiv.scrollLeft()

                iHeight = element.offsetHeight
                iWidth = element.offsetWidth
                aiPos = @getPosition(element)

                # Correct viewport positioning for vertical scrolling
                if aiPos[1]+iHeight > iScrollTop+iViewportHeight
                    # Displayed element if off the bottom of the viewport
                    @setScrollTop(aiPos[1]+iHeight - iViewportHeight)
                else if aiPos[1] < iScrollTop
                    # Displayed element if off the top of the viewport
                    @setScrollTop(aiPos[1])

                # Correct viewport positioning for horizontal scrolling
                if aiPos[0] + iWidth > iScrollLeft + iViewportWidth
                    # Displayed element is off the bottom of the viewport
                    @setScrollLeft(aiPos[0] + iWidth - iViewportWidth)
                else if aiPos[0] < iScrollLeft
                    # Displayed element if off the Left of the viewport
                    @setScrollLeft(aiPos[0])

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
        eventFire: (eventType, cell) ->
            aEvents = @_oaoEvents[eventType]
            for eventElement in aEvents
                if eventElement['nCell'].has(cell)
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
            @eventFire("blur", element)

        ###
        # Get the position of an object on the rendered page
        # @param obj element of interest
        # @return the element position [left, right]
        ###
        getPosition : (obj) ->
            iLeft = 0
            iTop = 0
            if obj.offsetParent
                iLeft = obj.offsetLeft
                iTop = obj.offsetTop
            return [iLeft, iTop]

        ###
        # Calculates the x and y position in a table from a TD cell
        #
        # @param element cell of interest
        # @return [x, y] position of the element
        ###
        getCoordsFromCell : (element) ->
            id = element.attr('id')
            return null if id is undefined
            coords = id.substring(id.indexOf('-') + 1, id.length).split('a')
            return [
                parseInt(coords[0]),
                parseInt(coords[1])
            ]

        ###
        # Calculates the target TD cell from x and y coordinates
        # @param x coordinate
        # @param y coordinate
        # @return TD target
        ###
        getCellFromCoords : (x, y) ->
            element = $(@idPrefix + x + 'a' + y, @nBody)
            return null if element.length == 0
            return element
            # return @_targetTable.rows[y].cells[x] # <-- this sadly doesn't work

        ###
        # Focus on the element that has been clicked on by the user
        # @param event click event
        ###
        onClick : (event) ->
            nTarget = $(event.target).closest('td')
            if nTarget isnt @_nCurrentFocus
                @setFocus(nTarget)
                @captureKeys()

        ###
        # Start capturing key events for this table
        ###
        captureKeys : ->
            @blockKeyCaptureFlg = true unless @blockKeyCaptureFlg

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
            $(document).unbind('click', @onClickHandler) if (@_onClickHandler)
