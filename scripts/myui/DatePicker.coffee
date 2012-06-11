define ['jquery', 'cs!myui/Util', 'myui/i18n', 'cs!myui/TextField', 'cs!myui/KeyTable'], ($, Util, i18n, TextField, KeyTable) ->
    dateUtil = $.util.date
    mathUtil = $.util.math
    eventUtil = $.util.event

    class DatePicker extends TextField
        constructor : (options) ->
            @baseInitialize(options)
            @_mdpId = $('.my-datepicker-container').length + $('.my-datepicker').length + 1
            @targetElement = $(options.input) # make sure it's an element, not a string
            @visibleFlg = false
            # initialize the date control

            @options = $.extend({
                embedded: false,
                embeddedId: null,
                format: 'MM/dd/yyyy',
                popup: null,
                time: false,
                buttons: true,
                clearButton: true,
                yearRange: 10,
                closeOnClick: null,
                minuteInterval: 5,
                changeMonth: false,
                changeYear: false,
                showWeek: false,
                numberOfMonths : 1,
                selectOtherMonth : false,
                validate: null
            }, options or {})

            @useTimeFlg = @options.time is 'mixed'
            @options.format += ' hh:mm' if @options.time is 'mixed'

            if !@options.embedded and @targetElement
                @render(@targetElement)
            else if @options.embedded
                if !@targetElement
                    inputId = if @options.input then @options.input else 'myDatePicker' + @_mdpId
                    parent = if @options.embeddedId then @options.embeddedId else document.body
                    $(parent).append('<input type="hidden" id="'+inputId+'" name="'+inputId+'">')
                    @options.input = inputId
                    @targetElement = $(inputId)
                @show()

        render : (input) ->
            super(input)
            @targetElement = $(input)
            @targetElement = @targetElement.find('INPUT') unless @targetElement[0].tagName == 'INPUT'
            @options.popupBy = @targetElement
            @options.onchange = @targetElement.onchange
            unless @options.embedded
                @keyPressHandler = (event) => @_keyPress(event)
                @targetElement.keydown @keyPressHandler
                @decorate @targetElement

        decorate : (element) ->
            width = $(element).width()
            height = $(element).height()
            $(element).wrap('<div></div>') # date picker container
            $(element).css {width : (width - 29)+'px'}
            @container = $(element).parent()
            @container.addClass('my-datepicker-container');
            @container.id = @id + '-container';
            @container.css {width : width + 'px', height: height + 'px'}
            datePickerSelectBtn = $('<div></div>')
            datePickerSelectBtn.addClass 'my-datepicker-select-button'
            @container.append(datePickerSelectBtn);
            datePickerSelectBtn.click (event) =>
                event.stopPropagation()
                @show()

        ###
        # Shows date picker control.
        ###
        show : ->
            return if @visibleFlg
            @_parseDate()
            @_callback('beforeShow')
            @_initCalendarDiv()
            unless @options.embedded
                @_positionCalendarDiv()
                # set the click handler to check if a user has clicked away from the document
                @_closeIfClickedOutHandler = (event) => @_closeIfClickedOut(event)
                $(document).click @_closeIfClickedOutHandler
            @_callback('afterShow')
            @visibleFlg = true

        ###
        # Returns unique id.
        ###
        getId : ->
            return @_mdpId

        ###
        # Initializes calendar div structure.
        ###
        _initCalendarDiv : ->
            idx = 0
            html = []
            parent = null
            style = ''
            if @options.embedded
                parent = @targetElement.parent()
            else
                parent = if @options.embeddedId then $(@options.embeddedId) else $(document.body)
                style = 'position: absolute; visibility: hidden; left:0; top:0;'

            style += 'width: 270px;' if @options.numberOfMonths is 1

            html[idx++] = '<div id="my-datepicker-div'+@_mdpId+'" class="my-datepicker shadow all-round-corners" style="'+style+'">'
            html[idx++] = '    <div class="my-datepicker-top" style="clear:left"></div>'
            html[idx++] = '    <div class="my-datepicker-header all-round-corners" style="clear:left"></div>'
            html[idx++] = '    <div class="my-datepicker-body" style="clear:left"></div>'
            html[idx++] = '    <div class="my-datepicker-footer all-round-corners" style="clear:left"></div>' unless @options.embedded
            html[idx++] = '</div>'

            $(parent).append(html.join(''))
            @_calendarDiv = $('#my-datepicker-div'+@_mdpId)
            @_headerDiv = $('.my-datepicker-header', @_calendarDiv)
            @_bodyDiv = $('.my-datepicker-body', @_calendarDiv)
            @_footerDiv = $('.my-datepicker-footer', @_calendarDiv)
            @_initHeaderDiv()
            unless @options.embedded
                @_initButtonsDiv()
                @_initButtonDivBehavior()
            @_initCalendarGrid()
            @_initHeaderDivBehavior()
            @_updateHeader('&#160;')
            @setUseTime(@useTimeFlg)
            @_refresh()


        ###
        # Sets calendar absolute position.
        ###
        _positionCalendarDiv : ->
            return if @options.embedded
            above = false
            calendarHeight = @_calendarDiv.height()
            windowTop = $(window).scrollTop()
            windowHeight = $(window).height()
            e_dim = $(@options.popupBy).offset()
            e_top = e_dim.top
            e_top = e_top - @tableGrid.bodyDiv.scrollTop() if @tableGrid
            e_left = e_dim.left
            e_left = e_left - @tableGrid.bodyDiv.scrollLeft() if @tableGrid
            e_height = $(@options.popupBy).height()
            e_bottom = e_top + e_height

            above = true if ((e_bottom + calendarHeight) > (windowTop + windowHeight)) and (e_bottom - calendarHeight > windowTop)
            left_px = e_left + 'px';
            top_px = if above then (e_top - calendarHeight - 2) else (e_top + e_height + 10) + 'px'

            @_calendarDiv.css('left', left_px)
            @_calendarDiv.css('top', top_px)
            @_calendarDiv.css('visibility', '')

        ###
        # Initialize calendar header  estructure.
        ###
        _initHeaderDiv : ->
            headerDiv = @_headerDiv
            id = @_mdpId
            numberOfMonths = @options.numberOfMonths
            if numberOfMonths > 1
                @options.changeMonth = false
                @options.changeYear = false

            idx = 0
            html = []
            html[idx++] = '<a class="toolbar-button prev"><span class="icon" style="margin: 1px 0">&nbsp;</span></a>'
            html[idx++] = '<a class="toolbar-button next"><span class="icon" style="margin: 1px 0">&nbsp;</span></a>'
            html[idx++] = '<span id="mdpSelectedDate-'+id+'" class="selected-date"></span>'
            headerDiv.append html.join('')

        ###
        # Initialize calendar header behavior.
        ###
        _initHeaderDivBehavior : ->
            headerDiv = @_headerDiv
            bodyDiv = @_bodyDiv
            nextMonthButton = headerDiv.find('.next')
            prevMonthButton = headerDiv.find('.prev')

            nextMonthButton.click (event) =>
                @_navMonth(@date.getMonth() + 1)

            prevMonthButton.click (event) =>
                @_navMonth(@date.getMonth() - 1)

            @monthSelect = bodyDiv.find('.month')
            if @monthSelect
                @monthSelect.change (event) =>
                    @_navMonth $(':selected', @monthSelect).val()

            @yearSelect = bodyDiv.find('.year')
            if @yearSelect
                @monthSelect.change (event) =>
                    @_navYear $(':selected', @yearSelect).val()

        ###
        # Initialize calendar months table.
        ###
        _initCalendarGrid : ->
            bodyDiv = @_bodyDiv
            numberOfMonths = @options.numberOfMonths
            showWeek = @options.showWeek
            idx = 0
            html = []
            i = 0
            html[idx++] = '<table border="0" cellpadding="0" cellspacing="0" width="100%">'
            html[idx++] = '<thead>'
            html[idx++] = '<tr>'
            colspan = if showWeek then 8 else 7
            for i in [1..numberOfMonths]
                html[idx++] = '<th colspan="'+colspan+'">'
                if @options.changeMonth
                    html[idx++] = '<select class="month">'
                    html[idx++] = '<option value="'+month+'">'+dateUtil.getMonthNames()[month]+'</option>' for month in [0..11]
                    html[idx++] = '</select>';
                else
                    html[idx++] = '<span id="mdpMonthLabel-'+@_mdpId+'-'+i+'" class="month-label">'
                    html[idx++] = '</span>'


                if @options.changeYear
                    html[idx++] = '<select class="year">';
                    html[idx++] = '<option value="'+year+'">'+year+'</option>' for year in @_yearRange()
                    html[idx++] = '</select>'
                else
                    html[idx++] = '&nbsp;'
                    html[idx++] = '<span id="mdpYearLabel-'+@_mdpId+'-'+i+'" class="year-label">'
                    html[idx++] = '</span>'

                html[idx++] = '</th>'

            html[idx++] = '</tr>'
            html[idx++] = '<tr>'
            for i in [0...numberOfMonths]
                if showWeek
                    if i > 0
                        html[idx++] = '<th class="new-month-separator">Week</th>' # TODO hard coded
                    else
                        html[idx++] = '<th>Week</th>' # TODO hard coded


                $.each dateUtil.getWeekDays(), (index, weekday) ->
                    if i > 0 and index % 7 is 0 and !showWeek
                        html[idx++] = '<th class="new-month-separator">'+weekday+'</th>'
                    else
                        html[idx++] = '<th>'+weekday+'</th>'

            html[idx++] = '</tr>'
            html[idx++] = '</thead>'
            html[idx++] = '<tbody>'

            for i in [0...6]
                html[idx++] = '<tr class="row-' + i + '">'
                for j in [0...(7 * numberOfMonths)]
                    if showWeek and j % 7 == 0
                        if j > 0
                            html[idx++] = '<td class="week-number new-month-separator"><div></div></td>'
                        else
                            html[idx++] = '<td class="week-number"><div></div></td>'

                    className = 'day'
                    className += ' weekend' if (j % 7 is 0) or ((j + 1) % 7 is 0)
                    className += ' new-month-separator' if j > 0 and j % 7 is 0 and !showWeek
                    html[idx++] = '<td id="mdpC'+@_mdpId+'-'+j+'a'+i+'" class="'+className+'"><div></div></td>'

                html[idx++] = '</tr>'

            html[idx++] = '</tbody>'
            html[idx++] = '</table>'
            bodyDiv.append(html.join(''))
            @daysTable = $('table', bodyDiv)
            @_allCells = $('td.day', @daysTable)

        ###
        # Initialize calendar buttons structure.
        ###
        _initButtonsDiv : ->
            footerDiv = @_footerDiv
            idx = 0
            html = []
            if @options.time
                html[idx++] = '<span class="time-controls">'
                timeItems = [if @options.time is 'mixed' then [' - ', ''] else []] # TODO check this
                currentTime = new Date()
                html[idx++] = '<select class="hour">'
                timeItems = [0..23].map (hour) ->
                    currentTime.setHours(hour)
                    [dateUtil.getAmPmHour(currentTime) + ' ' + dateUtil.getAmPm(currentTime), hour] # TODO check this
                html[idx++] = '<option value="'+hour[1]+'">'+hour[0]+'</option>' for hour in timeItems
                html[idx++] = '</select>'
                html[idx++] = '<span class="separator">&nbsp;:&nbsp;</span>'
                html[idx++] = '<select class="minute">'
                hours = [0..59].filter (min) =>
                    min % @options.minuteInterval is 0
                timeItems = hours.map min ->
                    [min.toPaddedString(2), min]
                html[idx++] = '<option value="'+min[1]+'">'+min[0]+'</option>' for min in timeItems
                html[idx++] = '</select>'
                html[idx++] = '</span>'
            else if !@options.buttons
                footerDiv.remove() # TODO review this condition

            if @options.buttons
                html[idx++] = '<span class="button-controls">'
                if @options.time == 'mixed' or !@options.time
                    html[idx++] = '<a href="#" class="toolbar-button today-button"><span class="text">'+i18n.getMessage('label.today')+'</span></a>'

                if @options.time
                    html[idx++] = '<a href="#" class="toolbar-button now-button"><span class="text">'+i18n.getMessage('label.now')+'</span></a>'

                if !@options.embedded and !@_closeOnClick()
                    html[idx++] = '<a href="#" class="toolbar-button close-button"><span class="text">'+i18n.getMessage('label.ok')+'</span></a>'

                if @options.clearButton
                    html[idx++] = '<a href="#" class="toolbar-button clear-button"><span class="text">'+i18n.getMessage('label.clear')+'</span></a>'

                html[idx++] = '</span>';

            footerDiv.append html.join('')

        ###
        # Initialize buttons behavior
        ###
        _initButtonDivBehavior : ->
            footerDiv = @_footerDiv
            @hourSelect = footerDiv.find('.hour')
            @minuteSelect = footerDiv.find('.minute')

            if @hourSelect
                @hourSelect.change (event) =>
                    @_updateSelectedDate {hour: $(':selected', @hourSelect).val()}

            if @minuteSelect
                @minuteSelect.change (event) =>
                    @_updateSelectedDate {minute: $(':selected', @minuteSelect)}

            todayButton = footerDiv.find('.today-button')
            if todayButton
                todayButton.click (event) => @_today(false)

            nowButton = footerDiv.find('.now-button')
            if nowButton
                nowButton.click (event) => @_today(true)

            closeButton = footerDiv.find('.close-button')
            if closeButton
                closeButton.click (event) => @_close()

            clearButton = footerDiv.find('.clear-button')
            if clearButton
                clearButton.click (event) =>
                    @clearDate()
                    @_close() unless @options.embedded
            return

        ###
        # Refresh all areas od the calendar.
        ###
        _refresh : ->
            @_refreshMonthYear()
            @_refreshCalendarGrid()
            @_setSelectedClass()
            @_updateHeader()
            @_applyKeyboardBehavior()

        ###
        # Refresh calendar table, determines month days and position.
        ###
        _refreshCalendarGrid : ->
            numberOfMonths = @options.numberOfMonths
            showWeek = @options.showWeek
            selectOtherMonth = @options.selectOtherMonth
            beginningDate = dateUtil.stripTime(@date)
            beginningMonth = @date.getMonth()
            beginningYear = @date.getFullYear()
            today = dateUtil.stripTime(new Date())
            @todayCell.removeClass('today') if @todayCell
            for m in [1..numberOfMonths]
                beginningDate = new Date(beginningYear, beginningMonth, 1)
                beginningDate.setHours(12) # Prevent daylight savings time boundaries from showing a duplicate day
                preDays = beginningDate.getDay() # draw some days before the fact
                beginningDate.setDate(1 - preDays + dateUtil.getFirstDayOfWeek())
                setTodayFlg = false
                daysUntil = dateUtil.daysDistance(beginningDate, today)
                if daysUntil in [0..41] and !setTodayFlg and today.getMonth() == beginningMonth
                    @todayCell = @_getCellByIndex(daysUntil, m).addClass('today')
                    setTodayFlg = true

                for i in [0...42]
                    day = beginningDate.getDate()
                    month = beginningDate.getMonth()
                    cell = @_getCellByIndex(i, m)
                    updateFlg = true
                    weekCell = null
                    if i % 7 == 0 and showWeek and (month == beginningMonth or i == 0)
                        weekCell = cell.prev()
                        weekCell.addClass('week-number')
                        weekCell.children().first().html(dateUtil.getWeek(beginningDate))
                    else
                        weekCell = cell.prev()
                        weekCell.removeClass('week-number') if weekCell

                    div = cell.children().first() # div element
                    if (month != beginningMonth)
                        div.addClass('other')
                        updateFlg = false unless selectOtherMonth
                    else
                        div.removeClass('other')

                    if (updateFlg)
                        {x, y} = @_getCellCoords(i, m)
                        cell.addClass('day')
                        cell.addClass('weekend') if (x % 7 is 0) or ((x + 1) % 7 is 0)
                        cell.attr('id', 'mdpC'+@_mdpId+'-'+x+'a'+y)
                        div.html(day)
                        cell.data('day', day)
                        cell.data('month', month)
                        cell.data('year', beginningDate.getFullYear())
                    else
                        cell.removeClass('day')
                        cell.removeClass('weekend')
                        cell.removeAttr('id')
                        div.html('&nbsp;')
                        if (showWeek && i % 7 == 0 && i > 7 * numberOfMonths)
                            weekCell = cell.prev()
                            weekCell.children().first().html('&nbsp;')

                    beginningDate.setDate(day + 1)

                if (beginningMonth + 1) > 11
                    beginningMonth = 0
                    beginningYear++
                else
                    beginningMonth++

        ###
        # Returns cell array offset
        # @param index: must be a number between 0 and 42
        # @param monthIdx: month index
        ###
        _getCellOffset : (index, monthIdx) ->
            numberOfMonths = @options.numberOfMonths
            row = Math.floor(index / 7)
            offset = index
            if monthIdx > 1
                offset += (monthIdx - 1) * (row + 1) * 7

            if numberOfMonths > 1 and row > 0
                offset += (numberOfMonths - monthIdx) * row * 7

            return offset

        ###
        # Returns cell element that represents a day in calendar estructure.
        ###
        _getCellByIndex : (index, monthIdx) ->
            offset = @_getCellOffset(index, monthIdx)
            return $(@_allCells[offset])

        ###
        # Returns x, y coords for a given array index
        ###
        _getCellCoords : (index, monthIdx) ->
            numberOfMonths = @options.numberOfMonths
            offset = @_getCellOffset(index, monthIdx)
            x = offset % (7 * numberOfMonths)
            y = Math.floor(index / 7)
            return {x, y}

        ###
        # Refresh months and years at header bar area
        ###
        _refreshMonthYear : ->
            month = @date.getMonth()
            year = @date.getFullYear()
            numberOfMonths = @options.numberOfMonths
            if @options.changeMonth
                @_setSelectBoxValue(@monthSelect, month)
            else
                for i in [1..numberOfMonths]
                    $('#mdpMonthLabel-'+@_mdpId+'-'+i).html(dateUtil.getMonthNames()[month])
                    if (month + 1) > 11
                        month = 0
                    else
                        month++

            if @options.changeYear
                if @_flexibleYearRange() and (!@_setSelectBoxValue(@yearSelect, year) or @yearSelect.selectedIndex <= 1 or @yearSelect.selectedIndex >= @yearSelect.options.length - 2)
                    idx = 0
                    html = []
                    html[idx++] = '<option value="'+year+'">'+year+'</option>' for year in @_yearRange()
                    @yearSelect.html html.join('')
                @_setSelectBoxValue(@yearSelect, year)
            else
                month = @date.getMonth()
                for i in [1..numberOfMonths]
                    $('#mdpYearLabel-'+@_mdpId+'-'+i).html(year)
                    if (month + 1) > 11
                        month = 0
                        year++
                    else
                        month++
        ###
        # Returns year range
        ###
        _yearRange : ->
            return [@options.yearRange[0]..@options.yearRange[1]] unless @_flexibleYearRange()
            currentYear = @date.getFullYear()
            return [(currentYear - @options.yearRange)..(currentYear + @options.yearRange)]

        ###
        # Generates select input box.
        ###
        _setSelectBoxValue: (selectElement, value) ->
            matched = false
            for i in [0...selectElement.options.length]
                if selectElement.options[i].value == value.toString()
                    selectElement.selectedIndex = i
                    matched = true
            return matched

        ###
        # Is year range provided?
        # Always true since options.yearRange default value is 10
        ###
        _flexibleYearRange : ->
            typeof(@options.yearRange) == 'number'

        ###
        # It is a valid year?
        ###
        _validYear : (year) ->
            if @_flexibleYearRange()
                return true
            else
                return year in @_yearRange()

        ###
        # Mouseenter handler.
        ###
        _dayHover : (cell) ->
            hoverDate = new Date(@selectedDate)
            hoverDate.setYear(cell.data('year'))
            hoverDate.setMonth(cell.data('month'))
            hoverDate.setDate(cell.data('day'))
            @_updateHeader(dateUtil.format(hoverDate, @options.format)) if dateUtil.isDate(hoverDate)
            @_keys.setFocus(cell, false)

        ###
        # Mouseleave handler.
        ###
        _dayHoverOut : (cell) ->
            @_keys.removeFocus(cell)
            @_updateHeader()

        ###
        # On click handler.
        ###
        _dayClick : (cell) ->
            @_keys.setFocus(cell, false)
            @_updateSelectedDate(cell, true)

        ###
        # Clears focus of selected class.
        ###
        _clearSelectedClass : ->
            @selectedCell.removeClass('selected') if @selectedCell

        ###
        # Sets selected class.
        ###
        _setSelectedClass : ->
            return unless @selectionMade
            @_clearSelectedClass()
            selectedDate = dateUtil.stripTime(@selectedDate)
            numberOfMonths = @options.numberOfMonths
            beginningDate = dateUtil.stripTime(@date)
            beginningMonth = @date.getMonth()
            beginningYear = @date.getFullYear()

            for m in [1..numberOfMonths]
                beginningDate = new Date(beginningYear, beginningMonth, 1)
                beginningDate.setHours(12) # Prevent daylight savings time boundaries from showing a duplicate day
                preDays = beginningDate.getDay() # draw some days before the fact
                beginningDate.setDate(1 - preDays + dateUtil.getFirstDayOfWeek())
                setTodayFlg = false
                daysUntil = dateUtil.daysDistance(beginningDate, selectedDate)
                if daysUntil in [0..41] and !setTodayFlg
                    @selectedCell = @_getCellByIndex(daysUntil, m).addClass('selected')
                    setTodayFlg = true

                if (beginningMonth + 1) > 11
                    beginningMonth = 0
                    beginningYear++
                else
                    beginningMonth++

        ###
        # Returns selected date applying format.
        ###
        dateString : ->
            return if @selectionMade then dateUtil.format(@selectedDate, @options.format) else '&#160;'

        ###
        # Returns input value.
        ###
        getValue : ->
            if @input.val() != null and @input.val().trim().length > 0
                return dateUtil.parseString(@input.val(), @options.format)
            return null

        ###
        # Returns selected date.
        ###
        _parseDate : ->
            value = @targetElement.val().trim()
            @selectionMade = (value != '')
            @date = if value == '' then NaN else dateUtil.parseString(@options.date or value, @options.format)
            @date = new Date() if isNaN(@date) or @date == null
            if !@_validYear(@date.getFullYear())
                yearRange = @_yearRange()
                year = if @date.getFullYear() < yearRange[0] then yearRange[0] else yearRange[yearRange.length - 1]
                @date.setYear(year)
            @selectedDate = @date

        ###
        # Updates calendar header text.
        ###
        _updateHeader : (text) ->
            text = @dateString() unless text
            $('#mdpSelectedDate-'+@_mdpId).html(text)

        ###
        # Clears calendar date.
        ###
        clearDate : ->
            return false if @targetElement.is(':disabled') or @targetElement.attr('readonly')
            lastValue = @targetElement.val()
            @targetElement.val('')
            @_clearSelectedClass()
            @_updateHeader('&#160;')
            @_callback('onchange') if lastValue != @targetElement.val()

        ###
        # Update selected date from calendar.
        ###
        _updateSelectedDate : (partsOrElement, viaClickFlg) ->
            return if @targetElement.is(':disabled') or @targetElement.attr('readonly')
            @setUseTime(false)
            selectedDate = new Date()
            if partsOrElement['day']
                selectedDate.setDate(partsOrElement['day'])
                selectedDate.setYear(partsOrElement['year'])
                selectedDate.setMonth(partsOrElement['month'])
                if !isNaN(partsOrElement['hour']) and !isNaN(partsOrElement['minute'])
                    selectedDate.setHours(partsOrElement['hour'])
                    selectedDate.setMinutes(mathUtil.floorToInterval(partsOrElement['minute'], @options.minuteInterval))
                    @setUseTime(true)
            else if partsOrElement instanceof jQuery
                selectedDate.setDate(partsOrElement.data('day'))
                selectedDate.setYear(partsOrElement.data('year'))
                selectedDate.setMonth(partsOrElement.data('month'))

            unless dateUtil.equals(selectedDate, @selectedDate)
                @selectedDate = selectedDate
                @selectionMade = true

            @_updateHeader()
            @_setSelectedClass()

            if @selectionMade
                @_updateValue()
                @validate()

            @_close() if @_closeOnClick()
            @options.afterUpdate(@targetElement, selectedDate) if @options.afterUpdate

            return unless viaClickFlg and !@options.embedded
            @_close()
            @targetElement.focus()

        _closeOnClick : ->
            return false if @options.embedded
            if @options.closeOnClick is null
                return !@options.time

            return @options.closeOnClick

        ###
        # Displays given month.
        ###
        _navMonth : (month) ->
            targetDate = new Date(@date)
            targetDate.setMonth(month)
            return @_navTo(targetDate)

        ###
        # Displays calendar month and year.
        ###
        _navYear : (year) ->
            targetDate = new Date(@date)
            targetDate.setYear(year)
            return @_navTo(targetDate)

        ###
        # Displays month of selected date.
        ###
        _navTo : (date) ->
            return false unless @_validYear(date.getFullYear())
            @date = date
            @date.setDate(1)
            @_refresh()
            @_callback('after_navigate', @date)
            return true;

        setUseTime : (turnOnFlg) ->
            return if @options.embedded
            @useTimeFlg = true
            @useTimeFlg = turnOnFlg if @options.time and @options.time == 'mixed'
            if @useTimeFlg and @selectedDate # only set hour/minute if a date is already selected
                minute = mathUtil.floorToInterval(@selectedDate.getMinutes(), @options.minuteInterval)
                hour = @selectedDate.getHours()
                @hourSelect.val(hour)
                @minuteSelect.val(minute)
            else if @options.time == 'mixed'
                @hourSelect.val('')
                @minuteSelect.val('')

        ###
        # Updates input element.
        ###
        _updateValue : ->
            lastValue = @targetElement.val()
            @targetElement.val(@dateString())
            @_callback('onchange') if lastValue != @targetElement.val()

        ###
        # Today button click handler.
        ###
        _today : (nowFlg) ->
            date = new Date()
            @date = new Date()
            parts =
                day: date.getDate()
                month: date.getMonth()
                year: date.getFullYear()
            if nowFlg
                parts['hour'] = date.getHours()
                parts['minute'] = date.getMinutes()
            @_updateSelectedDate(parts, true)
            @_refresh();

        ###
        # Close handler.
        ###
        _close : ->
            return false unless @visibleFlg
            @_callback('beforeClose')
            $(document).unbind('click', @_closeIfClickedOutHandler)
            @_calendarDiv.remove()
            @_keys.releaseKeys()
            @_keys.stop()
            @_keys = null
            @visibleFlg = false
            @_callback('afterClose')

        ###
        # Close if clicked out handler.
        ###
        _closeIfClickedOut : (event) ->
            target = $(event.target)
            @_close() if target.closest(@_calendarDiv).size() == 0 and target.closest(@container).size() == 0

        ###
        # Keydown handler
        ###
        _keyPress : (event) ->
            keyCode = event.which
            if keyCode == eventUtil.KEY_DOWN and !@visibleFlg
                @show()
                event.stopPropagation()
                @_keys.captureKeys()
            else if keyCode == eventUtil.KEY_ESC and @visibleFlg
                @_close()
                event.stopPropagation()
            return true

        ###
        # Callback handler.
        ###
        _callback : (name, param) ->
           @options[name].bind(@targetElement)(param) if @options[name]

        ###
        # Apply keyboard behavior.
        ###
        _applyKeyboardBehavior : ->
            numberOfMonths = @options.numberOfMonths
            @_keys = new KeyTable(@daysTable, {
                idPrefix : '#mdpC'+@_mdpId+'-',
                numberOfColumns : numberOfMonths * 7
            })

            f_focus = (cell) =>
                @_dayHover(cell)

            f_action = (cell) =>
                @_updateSelectedDate(cell, true)

            f_hover = (event) =>
                cell = $(event.target).closest('td')
                @_dayHover(cell)

            f_hoverOut = (event) =>
                cell = $(event.target).closest('td')
                @_dayHoverOut(cell)

            f_click = (event) =>
                cell = $(event.target).closest('td')
                @_dayClick(cell)

            for element in @_allCells
                $(element).unbind 'mouseenter'
                $(element).unbind 'mouseleave'
                $(element).unbind 'click'
                @_keys.event.remove.focus $(element)
                @_keys.event.remove.action $(element)
                if $(element).hasClass('day')
                    $(element).mouseenter f_hover
                    $(element).mouseleave f_hoverOut
                    $(element).click f_click
                    @_keys.event.focus $(element), f_focus
                    @_keys.event.action $(element), f_action
            # Select the first not empty cell
            selectedCell = @selectedCell or $('td.day:first', @_bodyDiv)
            @_dayHover(selectedCell)

