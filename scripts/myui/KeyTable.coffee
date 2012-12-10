define ['jquery', 'cs!myui/Util'], ($, Util) ->

    eventUtil = $.util.event

    class KeyTable
        constructor : (targetTable, options) ->
            @options = $.extend({
                idPrefix : '',
                cellFocusClass : 'focus',
                firstRowElement : null
            }, options or {})

            @_tableGrid = null
            @_cm = null # column model

            if targetTable._columnModel? # Is a TableGrid object?
                @_cm = targetTable._columnModel
                @_numberOfRows = targetTable.rows.length
                @_numberOfColumns = targetTable._columnModel.length
                @_tableGrid = targetTable
                @_bodyDiv = $(targetTable.bodyDiv)
                @_targetTable = $(targetTable.bodyTable)
            else if targetTable.is('table')
                @_cm = @_buildColumnModel(targetTable)
                @_targetTable = $(targetTable) # a normal table
                @_numberOfRows = @_targetTable.find('tbody > tr').length
                @_numberOfColumns = options.numberOfColumns or @_targetTable.find('tbody > tr')[0].cells.length

            @options.idPrefix = '#mtgC'+ @_tableGrid._mtgId + '_' if @_tableGrid?

            @_tableBody = @_targetTable.find('tbody') # Cache the tbody node of interest
            @_xCurrentPos = null
            @_yCurrentPos = null
            @_nCurrentFocus = null
            @_nOldFocus = null
            @_topLimit = 0
            # Table grid key navigation handling flags
            @_blockKeyCaptureFlg = true
            @_isInputFocusedFlg = false
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

            # Use the template functions to add the event API functions
            for eventName in ["action", "esc", "focus", "blur"]
                @events[eventName] = @_insertAddEventTemplate(eventName)
                @events.remove[eventName] = @_insertRemoveEventTemplate(eventName)

            # adding events object to each column model element
            c["events"] = {} for c in @_cm

            # Loose table focus when click outside the table
            @_onClickHandler = (event) =>
                return unless @_nCurrentFocus?
                element = $(event.target)
                blurFlg = true
                blurFlg = false if element.closest(@_targetTable).length > 0
                blurFlg = false if element.closest('my-autocompleter, my-autocompleter-list, my-datepicker-container').length > 0
                if blurFlg
                    @removeFocus(@_nCurrentFocus, true)
                    @_nOldFocus = null

            $(document).on 'click', @_onClickHandler

            @_tableBody.on 'click', (event) =>
                cell = $(event.target).closest('td')
                if cell isnt @_nCurrentFocus
                    @setFocus(cell)
                    @captureKeys()
                @_eventFire('focus', cell)

            @_tableBody.on 'dblclick', (event) =>
                cell = $(event.target).closest('td')
                @_eventFire('action', cell)

            @_onKeyPressHandler = (event) =>
                if @_onKeyPress(event)
                    event.stopPropagation()
                    event.preventDefault()

            $(document).on 'keydown', @_onKeyPressHandler


        ###
        # Purpose:  Create a function (with closure for eventName) event addition API
        # Returns:  function: - template function
        # Inputs:   string: eventName - type of event to detect
        ###
        _insertAddEventTemplate : (eventName) ->
            ###
            # API function for adding event to cache
            # Notes: This function is (interally) overloaded (in as much as javascript allows for that)
            #
            # Parameters:  1. c - column model element to add event for
            #              2. f - callback function to apply
            ###
            (c, f) => @_addEvent(eventName, c, f)


        ###
        # Purpose:  Create a function (with closure for eventName) event removal API
        # Returns:  function: - template function
        # Inputs:   string: eventName - type of event to detect
        ###
        _insertRemoveEventTemplate : (eventName) ->
            ###
            # API function for removing event from cache
            # Returns: number of events removed
            # Notes: This function is (internally) overloaded (in as much as javascript allows for that)
            #
            # Parameters: 1. c - column model element to remove event from
            ###
            (c) => @_removeEvent(eventName, c)


        ###
        # Add an event to the internal cache
        #
        # @param eventType type of event to add, given by the available elements in _oaoEvents
        # @param c column model element to add event too
        # @param f callback function for when triggered
        ###
        _addEvent : (eventType, c, f) ->
            c.events[eventType] = f

        ###
        # Removes an event from the event cache
        #
        # @param eventType type of event to look for
        # @param c column model element
        # @param f remove function.
        ###
        _removeEvent : (eventType, c) ->
            delete c.events[eventType]


        ###
        # Handles key events moving the focus from one cell to another
        #
        # @param event key event
        ###
        _onKeyPress : (event) ->
            return false if @_blockKeyCaptureFlg
            console.log 'processing key tableGrid? ' + @_tableGrid?
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
                        return false
                    when -1, eventUtil.KEY_LEFT # left arrow
                        return false if @_isInputFocusedFlg
                        if @_xCurrentPos > 0
                            x = @_xCurrentPos - 1
                            y = @_yCurrentPos
                        else if @_yCurrentPos > topLimit
                            x = @_numberOfColumns - 1
                            y = @_yCurrentPos - 1
                        else
                            return true
                        break
                    when eventUtil.KEY_UP # up arrow
                        return false if @_isInputFocusedFlg
                        if @_yCurrentPos > topLimit
                            x = @_xCurrentPos
                            y = @_yCurrentPos - 1
                        else
                            return true
                        break
                    when eventUtil.KEY_TAB, eventUtil.KEY_RIGHT # right arrow
                        return false if @_isInputFocusedFlg
                        if @_xCurrentPos < @_numberOfColumns - 1
                            x = @_xCurrentPos + 1
                            y = @_yCurrentPos
                        else if @_yCurrentPos < @_numberOfRows - 1
                            x = 0
                            y = @_yCurrentPos + 1
                        else
                            return true
                        break
                    when eventUtil.KEY_DOWN # down arrow
                        return false if @_isInputFocusedFlg
                        if @_yCurrentPos < @_numberOfRows - 1
                            x = @_xCurrentPos
                            y = @_yCurrentPos + 1
                        else
                            return true
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
            element.addClass(@options.cellFocusClass)
            element.closest('tr').addClass(@options.cellFocusClass)
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
                pos = element.position()

                # Correct viewport positioning for vertical scrolling
                if pos.top+height > scrollTop+viewportHeight
                    # Displayed element if off the bottom of the viewport
                    @setScrollTop(pos.top+height - viewportHeight)
                else if pos.top < scrollTop
                    # Displayed element if off the top of the viewport
                    @setScrollTop(pos.top)

                # Correct viewport positioning for horizontal scrolling
                if pos.left + width > scrollLeft + viewportWidth
                    # Displayed element is off the bottom of the viewport
                    @setScrollLeft(pos.left + width - viewportWidth)
                else if pos.left < scrollLeft
                    # Displayed element if off the Left of the viewport
                    @setScrollLeft(pos.left)

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
        _eventFire: (eventName, cell) ->
            cm = @_cm
            coords = @getCoordsFromCell(cell)
            x = coords[0]
            y = coords[1]
            if cm[x].events[eventName]?
                cm[x].events[eventName](cell)
                return true
            return false

        ###
        # Removes focus from a cell and fire any blur events which are attached
        # @param element cell of interest
        ###
        removeFocus : (element, onlyCellFlg = true) ->
            return unless element
            element.removeClass(@options.cellFocusClass)
            element.closest('tr').removeClass(@options.cellFocusClass) unless onlyCellFlg
            @_eventFire("blur", element)

        ###
        # Calculates the x and y position in a table from a TD cell
        #
        # @param element cell of interest
        # @return [x, y] position of the element
        ###
        getCoordsFromCell : (cell) ->
            id = $(cell).attr('id')
            return null unless id?
            match = id.match(/c(\d*?)r(\-?\d*?)$/)
            return [
                parseInt(match[1]),
                parseInt(match[2])
            ]
            #[cell.index(), cell.parent('tr').index()]

        ###
        # Calculates the target TD cell from x and y coordinates
        # @param x coordinate
        # @param y coordinate
        # @return TD target
        ###
        getCellFromCoords : (x, y) ->
            cell = $(@options.idPrefix + 'c' + x + 'r' + y, @_tableBody)
            return null if cell.length == 0
            return cell
            #return $('tr:eq('+y+')>td:eq('+x+')', @_targetTable)

        ###
        # Start capturing key events for this table
        ###
        captureKeys : ->
            @_blockKeyCaptureFlg = false

        ###
        # Stop capturing key events for this table
        ###
        releaseKeys : ->
            @_blockKeyCaptureFlg = true

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
            $(document).unbind('keydown', @_onKeyPressHandler)
            $(document).unbind('click', @_onClickHandler)

        ###
        # Build column model for an html table
        ###
        _buildColumnModel : (table) ->
            cm = []
            firstRow = @options.firstRowElement
            firstRow = $('tr:first', table) unless firstRow?
            headerColumns = if firstRow.has('th').size() > 0 then firstRow.find('th') else firstRow.find('td')
            if (headerColumns != null)
                headerColumns.each (index) ->
                    c = {}
                    cell = $(this)
                    c.id = if cell.is('[id]') then cell.attr('id') else 'column' + index
                    c.title = cell.text()
                    c.editable = false
                    c.positionIndex = index
                    cm.push(c)
            return cm