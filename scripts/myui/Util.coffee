define ['jquery', 'myui/i18n'], ($, i18n) ->
    event =
        KEY_BACKSPACE: 8
        KEY_TAB:       9
        KEY_RETURN:   13
        KEY_ESC:      27
        KEY_LEFT:     37
        KEY_UP:       38
        KEY_RIGHT:    39
        KEY_DOWN:     40
        KEY_DELETE:   46
        KEY_HOME:     36
        KEY_END:      35
        KEY_PAGEUP:   33
        KEY_PAGEDOWN: 34
        KEY_INSERT:   45

    math =
        ###
        # Returns the closest number as the result of using i as a multiplication factor
        # @param n limit number
        # @param i factor number
        ###
        floorToInterval : (n, i) ->
            return Math.floor(n / i) * i

    number =
        toPaddedString : (num, length, radix) ->
            string = num.toString(radix or 10)
            times = length - string.length
            return ('0' for i in [0...times]).join('') + string

    ###
    # Date functions
    # These functions are used to parse, format, and manipulate Date objects.
    # See documentation and examples at http://www.JavascriptToolbox.com/lib/date/
    ###

    ONE_DAY = 24 * 60 * 60 * 1000
    FIRST_DAY_OF_WEEK = 0
    # Utility function to append a 0 to single-digit numbers
    LZ = (x) ->
        x = '0' + x if x >= 0 and x <= 9
        return x

    isInteger = (val) ->
        for c in  val
            return false if '1234567890'.indexOf(c) == -1
        return true

    getInt = (str, i, minlength, maxlength) ->
        x = maxlength
        while x >= minlength
            token = str.substring(i, i + x)
            return null if token.length < minlength
            return token if isInteger(token)
            x--
        return null

    rotate = (arr, n) ->
        len = arr.length
        newArr = []
        for i in [n...len]
           newArr.push arr[i]

        for i in [0...n]
           newArr.push arr[i]
        return newArr


    template = (str , params) ->
        str = str.replace(new RegExp('{'+p+'}','g'), params[p]) for p of params
        return str

    preferAmericanFormat = true # TODO check this

    date =
        ###
        # Returns AM/PM time.
        ###
        getAmPmHour : (date) ->
            hour = date.getHours()
            return 12 if hour == 0
            return hour - 12 if hour > 12
            return hour

        ###
        # Returns whether is AM or PM time.
        ###
        getAmPm : (date) ->
            if date.getHours() < 12 then 'AM' else 'PM'

        ###
        # Trunks a given date removing hour, minutes and seconds.
        ###
        stripTime : (date) ->
            return new Date(date.getFullYear(), date.getMonth(), date.getDate())

        ###
        # Returns days distance as an absolute value.
        ###
        daysDistance : (date1, date2) ->
            Math.round((date2 - date1) / ONE_DAY)

        ###
        # Returns time difference in milliseconds between date1 and date2.
        # It is assumed that date1 is greater than date2.
        ###
        getDifference : (date1, date2) ->
            date1.getTime() - date2.getTime()

        ###
        # Returns UTC time for a given date.
        ###
        getUTCTime : (date) ->
            return Date.UTC(date.getFullYear(),
                date.getMonth(),
                date.getDate(),
                date.getHours(),
                date.getMinutes(),
                date.getSeconds(),
                date.getMilliseconds())

        ###
        # Returns UTC time difference between date1 and date2.
        ###
        getTimeSince : (date1, date2) ->
            date1.getUTCTime() - date2.getUTCTime()

        ###
        # Check if a date string is valid
        ###
        isValid : (val, format) ->
            return $.parseString(val, format) != null

        ###
        # Check if a date object is before another date object
        ###
        isBefore : (date1, date2) ->
            return false if date2 == null
            return date1.getTime() < date2.getTime()
        ###
        # Check if a date object is after another date object
        ###
        isAfter : (date1, date2) ->
            return false if date2 == null
            return date1.getTime() > date2.getTime()

        ###
        # Check if two date objects have equal dates and times.
        ###
        equals : (date1, date2) ->
            return false if date2 == null
            return date1.getTime() == date2.getTime()

        ###
        # Verifies if given paramter is a date or not.
        ###
        isDate : (date) ->
            return (null != date) and !isNaN(date) and ("undefined" isnt typeof date.getDate)


        ###
        # Check if two date objects have equal dates, disregarding times.
        ###
        equalsIgnoreTime : (date1, date2) ->
            return false if date2 == null
            d1 = $.clearTime new Date(date1.getTime())
            d2 = $.clearTime new Date(date2.getTime())
            return d1.getTime() == d2.getTime()

        ###
        # Get the full name of the day for a date
        ###
        getDayName : (date) ->
            return @getDayNames()[date.getDay()]

        ###
        # Get the abbreviation of the day for a date
        ###
        getDayAbbreviation : (date) ->
            return @getDayAbbreviations()[date.getDay()]

        ###
        # Get the full name of the month for a date
        ###
        getMonthName : (date) ->
            return @getMonthNames()[date.getMonth()]

        ###
        # Get the abbreviation of the month for a date
        ###
        getMonthAbbreviation : (date) ->
            return @getMonthAbbreviations()[date.getMonth()]

        ###
        # Clear all time information in a date object
        ###
        clearTime : (date) ->
            date.setHours(0)
            date.setMinutes(0)
            date.setSeconds(0)
            date.setMilliseconds(0)
            return date

        ###
        # Parse a string and convert it to a Date object.
        # If no format is passed, try a list of common formats.
        # If string cannot be parsed, return null.
        # Avoids regular expressions to be more portable.
        ###
        parseString : (val, format) ->
            # If no format is specified, try a few common formats
            if typeof(format) == "undefined" or format == null or format == ""
                generalFormats = ['y-M-d', 'MMM d, y', 'MMM d,y', 'y-MMM-d', 'd-MMM-y', 'MMM d', 'MMM-d', 'd-MMM']
                monthFirst = ['M/d/y', 'M-d-y', 'M.d.y', 'M/d', 'M-d']
                dateFirst = ['d/M/y', 'd-M-y', 'd.M.y', 'd/M', 'd-M']
                if preferAmericanFormat
                    checkList = [generalFormats, monthFirst, dateFirst]
                else
                    checkList = [generalFormats, dateFirst, monthFirst]
                for l in checkList
                    for k in l
                        d = $.parseString(val, k)
                        return d if d != null
                return null

            val = val + ''
            format = format + ''
            i_val = 0
            i_format = 0
            c = ''
            token = ''
            token2 = ''
            year = new Date().getFullYear()
            month = 1
            date = 1
            hh = 0
            mm = 0
            ss = 0
            ampm = ''
            x = 0
            y = 0
            while i_format < format.length
                # Get next token from format string
                c = format.charAt(i_format)
                token = ''
                while format.charAt(i_format) == c and i_format < format.length
                    token += format.charAt(i_format++)
                # Extract contents of value based on format token
                if token == "yyyy" or token == "yy" or token == "y"
                    if token == "yyyy"
                        x = 4
                        y = 4
                    if token == "yy"
                        x = 2
                        y = 2
                    if token == "y"
                        x = 2
                        y = 4

                    year = getInt(val, i_val, x, y)
                    return null if year == null
                    i_val += year.length
                    if year.length == 2
                        if year > 70
                            year = 1900 + (year - 0)
                        else
                            year = 2000 + (year - 0)
                else if token == "MMM" or token == "NNN"
                    month = 0
                    names = @getMonthAbbreviations()
                    names = @getMonthNames().concat @getMonthAbbreviations() if token = "MMM"
                    for month_name, i in names
                        if (val.substring(i_val, i_val + month_name.length).toLowerCase() == month_name.toLowerCase())
                            month = (i % 12) + 1
                            i_val += month_name.length
                            break
                    return null if month < 1 or month > 12
                else if token == "EE" or token == "E"
                    names = @getDayAbbreviations()
                    names = @getDayNames() if token == "EE"
                    for day_name in names
                        if val.substring(i_val, i_val + day_name.length).toLowerCase() == day_name.toLowerCase()
                            i_val += day_name.length
                            break
                else if token == "MM" || token == "M"
                    month = getInt(val, i_val, token.length, 2)
                    return null if month == null or month < 1 or month > 12
                    i_val += month.length
                else if token == "dd" or token == "d"
                    date = getInt(val, i_val, token.length, 2)
                    return null if date == null or date < 1 or date > 31
                    i_val += date.length
                else if token == "hh" or token == "h"
                    hh = getInt(val, i_val, token.length, 2)
                    return null if hh == null or hh < 1 or hh > 12
                    i_val += hh.length
                else if token == "HH" or token == "H"
                    hh = getInt(val, i_val, token.length, 2)
                    return null if hh == null or hh < 0 || hh > 23
                    i_val += hh.length
                else if token == "KK" or token == "K"
                    hh = getInt(val, i_val, token.length, 2)
                    return null if hh == null or hh < 0 or hh > 11
                    i_val += hh.length
                    hh++
                else if token == "kk" or token == "k"
                    hh = getInt(val, i_val, token.length, 2)
                    return null if hh == null or hh < 1 or hh > 24
                    i_val += hh.length
                    hh--
                else if token == "mm" or token == "m"
                    mm = getInt(val, i_val, token.length, 2)
                    return null if mm == null or mm < 0 or mm > 59
                    i_val += mm.length
                else if token == "ss" or token == "s"
                    ss = getInt(val, i_val, token.length, 2)
                    return null if ss == null or ss < 0 or ss > 59
                    i_val += ss.length
                else if token == "a"
                    if val.substring(i_val, i_val + 2).toLowerCase() == "am"
                        ampm = "AM"
                    else if val.substring(i_val, i_val + 2).toLowerCase() == "pm"
                        ampm = "PM"
                    else
                        return null
                    i_val += 2
                else
                    if val.substring(i_val, i_val + token.length) != token
                        return null
                    else
                        i_val += token.length

            # If there are any trailing characters left in the value, it doesn't match
            return null if i_val != val.length
            # Is date valid for month?
            if month == 2
                # Check for leap year
                if (year % 4 == 0 and year % 100 != 0) or year % 400 == 0 # leap year
                    return null if date > 29
                else
                    return null if date > 28

            if month == 4 or month == 6 or month == 9 or month == 11
                return null if date > 30

            # Correct hours value
            if hh < 12 and ampm == "PM"
                hh = hh - 0 + 12
            else if hh > 11 and ampm == "AM"
                hh -= 12

            return new Date(year, month - 1, date, hh, mm, ss)

        # Format a date into a string using a given format string
        format : (date, format) ->
            format = format + ""
            result = ""
            i_format = 0
            c = ""
            token = ""
            y = date.getYear() + ""
            M = date.getMonth() + 1
            d = date.getDate()
            E = date.getDay()
            H = date.getHours()
            m = date.getMinutes()
            s = date.getSeconds()
            # yyyy, yy, MMM, MM, dd, hh, h, mm, ss, ampm, HH, H, KK, K, kk, k
            # Convert real date parts into formatted versions
            value = {}
            y = "" + (+y + 1900) if y.length < 4
            value["y"] = "" + y
            value["yyyy"] = y
            value["yy"] = y.substring(2, 4)
            value["M"] = M
            value["MM"] = LZ(M)
            value["MMM"] = @getMonthNames()[M - 1]
            value["NNN"] = @getMonthAbbreviations()[M - 1]
            value["d"] = d
            value["dd"] = LZ(d)
            value["E"] = @getDayAbbreviations()[E]
            value["EE"] = @getDayNames()[E]
            value["H"] = H
            value["HH"] = LZ(H)
            if H == 0
                value["h"] = 12
            else if (H > 12)
                value["h"] = H - 12
            else
                value["h"] = H

            value["hh"] = LZ(value["h"])
            value["K"] = value["h"] - 1
            value["k"] = value["H"] + 1
            value["KK"] = LZ(value["K"])
            value["kk"] = LZ(value["k"])
            if H > 11
                value["a"] = "PM"
            else
                value["a"] = "AM"
            value["m"] = m
            value["mm"] = LZ(m)
            value["s"] = s
            value["ss"] = LZ(s)
            while i_format < format.length
                c = format.charAt(i_format)
                token = ""
                while format.charAt(i_format) == c and i_format < format.length
                    token += format.charAt(i_format++)

                if typeof(value[token]) != "undefined"
                    result = result + value[token]
                else
                    result = result + token
            return result

        ###
        # Add an amount of time to a date. Negative numbers can be passed to subtract time.
        ###
        add : (date, interval, number) ->
            return date if typeof(interval) == "undefined" or interval == null or typeof(number) == "undefined" or number == null
            number = +number
            if interval == 'y' # year
                date.setFullYear(date.getFullYear() + number)
            else if interval == 'M'  # Month
                date.setMonth(date.getMonth() + number)
            else if interval == 'd' # Day
                date.setDate(date.getDate() + number)
            else if interval == 'w' # Weekday
                step = if number > 0 then 1 else -1
                while number != 0
                    date.add('d', step)
                    while date.getDay() == 0 or date.getDay() == 6
                        date.add('d', step)
                    number -= step
            else if interval == 'h' # Hour
                date.setHours(date.getHours() + number)
            else if interval == 'm' # Minute
                date.setMinutes(date.getMinutes() + number)
            else if interval == 's' # Second
                date.setSeconds(date.getSeconds() + number)
            return date


        ###
        # Get the ISO week number
        ###
        getWeek : (date) ->
            # Create a copy of this date object
            target = new Date(date.valueOf())

            # ISO week date weeks start on monday
            # so correct the day number
            dayNr = (date.getDay() + 6) % 7

            # ISO 8601 states that week 1 is the week
            # with the first thursday of that year.
            # Set the target date to the thursday in the target week
            target.setDate(target.getDate() - dayNr + 3)

            # Store the millisecond value of the target date
            firstThursday = target.valueOf()

            # Set the target to the first thursday of the year
            # First set the target to january first
            target.setMonth(0, 1)
            # Not a thursday? Correct the date to the next thursday
            if target.getDay() != 4
                target.setMonth(0, 1 + ((4 - target.getDay()) + 7) % 7)

            # The weeknumber is the number of weeks between the
            # first thursday of the year and the thursday in the target week
            return 1 + Math.ceil((firstThursday - target) / 604800000) # 604800000 = 7 * 24 * 3600 * 1000

        getWeekDays : ->
            weekDays = i18n.getMessage('date.weekDays')
            if FIRST_DAY_OF_WEEK > 0
                weekDays = rotate(weekDays, FIRST_DAY_OF_WEEK)
            return weekDays

        getMonthNames : ->
            return i18n.getMessage('date.monthNames')

        getMonthAbbreviations : ->
            return i18n.getMessage('date.monthAbbreviations')

        getDayNames : ->
            return i18n.getMessage('date.dayNames')

        getDayAbbreviations : ->
            return i18n.getMessage('date.dayAbbreviations')

        getFirstDayOfWeek : ->
            return FIRST_DAY_OF_WEEK

        setFirstDayOfWeek : (firstDayOfWeek) ->
            firstDayOfWeek = 1 if firstDayOfWeek > 1 # little validation only allow 0 or 1
            return FIRST_DAY_OF_WEEK = firstDayOfWeek

    util =
        math : math
        date : date
        event : event
        number : number
        template : template

    $.util = util
