define ['jquery', 'cs!myui/TextField'], ($, TextField) ->
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
            @targetElement = @targetElement.find('INPUT') unless @targetElement[0].tagName is 'INPUT'
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
            @container.id = @id + '_container';
            @container.css {width : width + 'px', height: height + 'px'}
            datePickerSelectBtn = $('<div></div>')
            datePickerSelectBtn.addClass 'my-datepicker-select-button'
            @container.append(datePickerSelectBtn);
            datePickerSelectBtn.click (event) =>
                event.stopPropagation()
                @show()

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

        getId : ->
            return @_mdpId


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
            @_headerDiv = @_calendarDiv.find('.my-datepicker-header')
            @_bodyDiv = @_calendarDiv.find('.my-datepicker-body')
            @_footerDiv = @_calendarDiv.find('.my-datepicker-footer')

            @_initHeaderDiv()
            unless @options.embedded
                @_initButtonsDiv()
                @_initButtonDivBehavior()

            @_initCalendarGrid()
            @_initHeaderDivBehavior()
            @_updateHeader('&#160;')
            @_refresh()
            @setUseTime(@useTimeFlg)
            @_applyKeyboardBehavior()

        _positionCalendarDiv : ->
            return if @options.embedded
            above = false
            calendarHeight = @_calendarDiv.height()
            windowTop = $(window).getScrollTop()
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
            top_px = if above then (e_top - calendarHeight - 2) else (e_top + e_height + 2) + 'px'

            @_calendarDiv.css('left', left_px)
            @_calendarDiv.css('top', top_px)
            @_calendarDiv.css('visibility', '')


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
            html[idx++] = '<span id="mdpSelectedDate_'+id+'" class="selected-date"></span>'
            headerDiv.append html.join('')


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


        _initCalendarGrid : ->
            bodyDiv = @_bodyDiv
            numberOfMonths = @options.numberOfMonths
            showWeek = @options.showWeek
            @_calendarDayGrid = []
            idx = 0
            html = []
            i = 0
            html[idx++] = '<table border="0" cellpadding="0" cellspacing="0" width="100%">'
            html[idx++] = '<thead>'
            html[idx++] = '<tr>'
            for i in [1..numberOfMonths]
                html[idx++] = '<th colspan="'+(showWeek ? '8' : '7')+'">'
                if @options.changeMonth
                    html[idx++] = '<select class="month">'
                    html[idx++] = '<option value="'+month+'">'+Date.MONTH_NAMES[month]+'</option>' for month in [0..11]
                    html[idx++] = '</select>';
                else
                    html[idx++] = '<span id="mdpMonthLabel_'+@_mdpId+'_'+i+'" class="month-label">'
                    html[idx++] = '</span>'


                if @options.changeYear
                    html[idx++] = '<select class="year">';
                    html[idx++] = '<option value="'+year+'">'+year+'</option>' for year in @yearRange()
                    html[idx++] = '</select>'
                else
                    html[idx++] = '&nbsp;'
                    html[idx++] = '<span id="mdpYearLabel_'+@_mdpId+'_'+i+'" class="year-label">'
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


                $.each Date.WEEK_DAYS, (index, weekday) ->
                    if i > 0 and index % 7 is 0 and !showWeek
                        html[idx++] = '<th class="new-month-separator">'+weekday+'</th>'
                    else
                        html[idx++] = '<th>'+weekday+'</th>'

            html[idx++] = '</tr>'
            html[idx++] = '</thead>'
            html[idx++] = '<tbody>'

            for i in [0...6]
                html[idx++] = '<tr class="row_' + i + '">'
                for j in [0...(7 * numberOfMonths)]
                    if showWeek and j % 7 == 0
                        if j > 0
                            html[idx++] = '<td class="week-number new-month-separator"><div></div></td>'
                        else
                            html[idx++] = '<td class="week-number"><div></div></td>'


                    className = 'day'
                    className += ' weekend' if (j % 7 is 0) or ((j + 1) % 7 is 0)
                    className += ' new-month-separator' if j > 0 and j % 7 is 0 and !showWeek
                    html[idx++] = '<td id="mdpC'+@_mdpId+'_'+j+','+i+'" class="'+className+'"><div></div></td>'

                html[idx++] = '</tr>'

            html[idx++] = '</tbody>'
            html[idx++] = '</table>'
            bodyDiv.append(html.join(''))
            @daysTable = bodyDiv.find('table')
            @_calendarDayGrid = @daysTable.find('.day')


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
                    [currentTime.getAMPMHour() + ' ' + currentTime.getAMPM(), hour] # TODO check this
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
                todayButton.click (event) => @today(false)

            nowButton = footerDiv.find('.now-button')
            if nowButton
                nowButton.click (event) => @today(true)

            closeButton = footerDiv.find('.close-button')
            if closeButton
                closeButton.click (event) => @_close()

            clearButton = footerDiv.find('.clear-button')
            if clearButton
                clearButton.click (event) =>
                    @clearDate()
                    @_close() unless @options.embedded
            return

        _refresh : ->
            @_refreshMonthYear()
            @_refreshCalendarGrid()
            @_setSelectedClass()
            @_updateHeader()

        _refreshCalendarGrid : ->
            numberOfMonths = @options.numberOfMonths
            showWeek = @options.showWeek
            selectOtherMonth = @options.selectOtherMonth
            beginningDate = @date.stripTime()
            beginningMonth = @date.getMonth()
            beginningYear = @date.getFullYear()
            today = new Date().stripTime()
            @todayCell.removeClass('today') if @todayCell
            for m in [1..numberOfMonths]
                beginningDate = new Date(beginningYear, beginningMonth, 1)
                beginningDate.setHours(12) # Prevent daylight savings time boundaries from showing a duplicate day
                preDays = beginningDate.getDay() # draw some days before the fact
                beginningDate.setDate(1 - preDays + Date.FIRST_DAY_OF_WEEK)
                setTodayFlg = false
                daysUntil = beginningDate.daysDistance(today)
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
                        weekCell.children().first().html(beginningDate.getWeek())
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
                        div.html(day)
                        cell.day = day
                        cell.month = month
                        cell.year = beginningDate.getFullYear()
                    else
                        cell.removeClass('day')
                        cell.removeClass('weekend')
                        cell.removeAttribute('id')
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

        _getCellByIndex : (index, monthIdx) ->
            numberOfMonths = @options.numberOfMonths
            row = Math.floor(index / 7)
            offset = index
            if monthIdx > 1
                offset += (monthIdx - 1) * (row + 1) * 7

            if numberOfMonths > 1 and row > 0
                offset += (numberOfMonths - monthIdx) * row * 7

            return @_calendarDayGrid[offset]

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
                    $('#mdpMonthLabel_'+@_mdpId+'_'+i).html(Date.MONTH_NAMES[month])
                    if (month + 1) > 11
                        month = 0
                    else
                        month++

            if @options.changeYear
                if @flexibleYearRange() and (!@_setSelectBoxValue(@yearSelect, year) or @yearSelect.selectedIndex <= 1 or @yearSelect.selectedIndex >= @yearSelect.options.length - 2)
                    idx = 0
                    html = []
                    html[idx++] = '<option value="'+year+'">'+year+'</option>' for year in @yearRange()
                    @yearSelect.html html.join('')
                @_setSelectBoxValue(@yearSelect, year)
            else
                month = @date.getMonth()
                for i in [1..numberOfMonths]
                    $('#mdpYearLabel_'+@_mdpId+'_'+i).html(year)
                    if (month + 1) > 11
                        month = 0
                        year++
                    else
                        month++

        yearRange : ->
            return [@options.yearRange[0]..@options.yearRange[1]] unless @flexibleYearRange()
            currentYear = @date.getFullYear()
            return [(currentYear - @options.yearRange)..(currentYear + @options.yearRange)]


        _setSelectBoxValue: (selectElement, value) ->
            matched = false
            for i in [0...selectElement.options.length]
                if selectElement.options[i].value == value.toString()
                    selectElement.selectedIndex = i
                    matched = true
            return matched

        flexibleYearRange : ->
            typeof(@options.yearRange) == 'number'

        validYear : (year) ->
            if @flexibleYearRange()
                return true
            else
                return year in @yearRange()

        _dayHover : (element) ->
            $(element).addClass('focus')
            hoverDate = new Date(@selectedDate)
            hoverDate.setYear(element.year)
            hoverDate.setMonth(element.month)
            hoverDate.setDate(element.day)
            @_updateHeader(hoverDate.format(@options.format))
            @keys.setFocus(element, false)

        _dayHoverOut : (element) ->
            $(element).removeClass('focus')
            @_updateHeader()

        _clearSelectedClass : ->
            @selectedCell.removeClass('selected') if @selectedCell

        _setSelectedClass : ->
            return unless @selectionMade
            @_clearSelectedClass()
            selectedDate = @selectedDate.stripTime()
            numberOfMonths = @options.numberOfMonths
            beginningDate = @date.stripTime()
            beginningMonth = @date.getMonth()
            beginningYear = @date.getFullYear()

            for m in [1..numberOfMonths]
                beginningDate = new Date(beginningYear, beginningMonth, 1)
                beginningDate.setHours(12) # Prevent daylight savings time boundaries from showing a duplicate day
                preDays = beginningDate.getDay() # draw some days before the fact
                beginningDate.setDate(1 - preDays + Date.FIRST_DAY_OF_WEEK)
                setTodayFlg = false
                daysUntil = beginningDate.daysDistance(selectedDate)
                if daysUntil in [0..41] and !setTodayFlg
                    @selectedCell = @_getCellByIndex(daysUntil, m).addClass('selected')
                    setTodayFlg = true

                if (beginningMonth + 1) > 11
                    beginningMonth = 0
                    beginningYear++
                else
                    beginningMonth++

        dateString : ->
            return if @selectionMade then @selectedDate.format(@options.format) else '&#160;'


        getValue : ->
            if @input.val() != null and @input.val().trim().length > 0
                return Date.parseString(@input.val(), @options.format)
            return null

        _parseDate : ->
            value = @targetElement.val().trim()
            @selectionMade = (value != '')
            @date = if value == '' then NaN else Date.parseString(@options.date or value, @options.format)
            @date = new Date() if isNaN(@date) or @date == null
            if !@validYear(@date.getFullYear())
                yearRange = @yearRange()
                year = if @date.getFullYear() < yearRange[0] then yearRange[0] else yearRange[yearRange.length - 1]
                @date.setYear(year)
            @selectedDate = @date


        _updateHeader : (text) ->
            text = @dateString() unless text
            $('#mdpSelectedDate_'+@_mdpId).html(text)

        clearDate : ->
            return false if (@targetElement.disabled or @targetElement.readOnly) and @options.popup != 'force'
            lastValue = @targetElement.val()
            @targetElement.value = ''
            @_clearSelectedClass()
            @_updateHeader('&#160;')
            @_callback('onchange') if lastValue != @targetElement.val()

        _updateSelectedDate : (partsOrElement, viaClickFlg) ->
            parts = partsOrElement
            return false if (@targetElement.disabled || @targetElement.readOnly) && @options.popup != 'force' #TODO check this
            if parts['day']
                selectedDate = @selectedDate
                selectedDate.setDate(parts['day']) for i in [0..3] #TODO Check this
                selectedDate.setYear(parts['year'])
                selectedDate.setMonth(parts['month'])
                @selectedDate = selectedDate
                @selectionMade = true

            if !isNaN(parts.get('hour'))
                @selectedDate.setHours(parts['hour'])

            if !isNaN(parts['minute'])
                @selectedDate.setMinutes(Utilities.floorToInterval(parts['minute'], @options.minuteInterval))

            if parts['hour'] is '' or parts['minute'] is ''
                @setUseTime(false)
            else if !isNaN(parts['hour']) or !isNaN(parts['minute'])
                @setUseTime(true)

            @_updateHeader()
            @_setSelectedClass()

            if @selectionMade
                @_updateValue()
                @validate()

            @_close() if @_closeOnClick()
            @options.afterUpdate(@targetElement, selectedDate) if @options.afterUpdate

            if viaClickFlg and !@options.embedded
                @_close()
                @targetElement.focus() if @targetElement.attr('type') != 'hidden' and !@targetElement.attr('disabled')

        _closeOnClick : ->
            return false if @options.embedded
            if @options.closeOnClick is null
                return !@options.time

            return @options.closeOnClick

        _navMonth : (month) ->
            targetDate = new Date(@date)
            targetDate.setMonth(month)
            return @_navTo(targetDate)

        _navYear : (year) ->
            targetDate = new Date(@date)
            targetDate.setYear(year)
            return @_navTo(targetDate)

        _navTo : (date) ->
            return false unless @validYear(date.getFullYear())
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
                minute = Utilities.floorToInterval(@selectedDate.getMinutes(), @options.minuteInterval)
                hour = @selectedDate.getHours()
                @hourSelect.setValue(hour)
                @minuteSelect.setValue(minute)
            else if @options.time == 'mixed'
                @hourSelect.setValue('')
                @minuteSelect.setValue('')

        _updateValue : ->
            lastValue = @targetElement.val()
            @targetElement.val(@dateString())
            @_callback('onchange') if lastValue != @targetElement.val()

        today : (now) -> # TODO review this method
            d = new Date()
            @date = new Date()
            o = {day: d.getDate(), month: d.getMonth(), year: d.getFullYear(), hour: d.getHours(), minute: d.getMinutes()}
            o = o.extend({hour: '', minute: ''}) unless now
            @_updateSelectedDate(o, true)
            @_refresh();

        _close : ->
            return false unless @visibleFlg
            @_callback('beforeClose')
            $(document).unbind('click', @_closeIfClickedOutHandler)
            @_calendarDiv.remove()
            @keys.stop()
            @keys = null
            @visibleFlg = false
            @_callback('afterClose')

        _closeIfClickedOut : (event) ->
            target = evemt.target
            @_close() if !target.closest(@_calendarDiv) && !target.closest(@container)


        _keyPress : (event) ->
            if event.which == Event.KEY_DOWN and !@visibleFlg
                @show()
                event.stopPropagation()
            else if event.which == Event.KEY_ESC and @visibleFlg
                @_close()
                event.stopPropagation()
            return true

        _callback : (name, param) -> # TODO really weird
           @options[name].bind(@targetElement)(param) if @options[name]

        _applyKeyboardBehavior : ->
            i = 0
            numberOfMonths = @options.numberOfMonths
            showWeek = @options.showWeek
            @keys = new KeyTable(@daysTable, {
                idPrefix : 'mdpC'+@_mdpId+'_',
                numberOfColumns : numberOfMonths * (showWeek ? 8 : 7)
            })
            for element in @_calendarDayGrid
                call = (element) =>
                    if element.hasClass('day')
                        element.mouseover (event) => @_dayHover(@)
                        element.mouseout (event) => @_dayHoverOut(@)
                        element.click (event) =>
                            @keys.setFocus(element, false)
                            @keys.captureKeys()
                            @keys.eventFire('focus', element)
                            @_updateSelectedDate(@, true)

                        @keys.event.remove.focus(element)
                        f_focus = (element) =>
                            td.removeClassName('focus') for td in @_calendarDayGrid
                            @_dayHover(element)

                        @keys.event.focus(element, f_focus)
                        @keys.event.remove.action(element)

                        f_action = (element) => @_updateSelectedDate(element, true)
                        @keys.event.action(element, f_action)
                call $(element)

            selectedCell = @selectedCell or $('mdpC'+@_mdpId+'_0,0')
            i = 0
            while (!selectedCell)
                selectedCell = $('mdpC'+@_mdpId+'_' +(++i)+',0')

            @keys.setFocus(selectedCell, false)
            @keys.captureKeys()
            @keys.eventFire('focus', selectedCell)
