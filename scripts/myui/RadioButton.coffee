define ['jquery'], ($) ->
    class RadioButton
        constructor : (options) ->
            @elements = $(options.input)

            @options = $.extend({
                onClick : null,
                getValueOf : null,
                tableGrid : null
            }, options or {})

            @onClick = options.onClick
            @getValueOf = options.getValueOf

            unless @options.tableGrid?
                @decorate()
                @addBehavior()

        decorate : ->
            @elements.wrap('<span class="my-radio"></span>')
            $(element).parent('span').addClass('my-radio-checked') for element in @elements when $(element).is(':checked')

        addBehavior : ->
            span = @elements.parent('span')
            span.on 'mousedown', (event) =>
                element = $(event.target)
                isChecked = $('input', element).is(':checked')
                unless isChecked
                    $(':checked', @elements).parent('span').removeClass('my-radio-checked')
                    element.addClass('my-radio-checked')
                @options.onClick(!isChecked, $(element)) if @options.onClick?

    $.fn.myRadioButton = (options = {}) ->
        options.input = @
        new RadioButton(options)
        return @