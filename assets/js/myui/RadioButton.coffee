define ['jquery'], ($) ->
    class RadioButton
        constructor : (options) ->
            @elements = $(options.input)
            @options = $.extend({
                onClick : null,
                getValueOf : null,
            }, options or {})
            @onClick = options.onClick
            @getValueOf = options.getValueOf
            @_decorate()
            @_addBehavior()

        _decorate : ->
            @elements.wrap('<label><div class="my-radio"></div></label>')
            $(element).parent('div').addClass('active') for element in @elements when $(element).is(':checked')
            @elements.append('<div></div>')

        _addBehavior : ->
            div = @elements.parent('div')
            div.on 'mousedown', (event) =>
                element = $(event.target)
                isChecked = $('input', element).is(':checked')
                name = $('input', element).attr('name')
                unless isChecked
                    $('input[name='+name+']').parent('div').removeClass('active')
                    element.addClass('active')
                @options.onClick(!isChecked, $(element)) if @options.onClick?

    $.fn.myRadioButton = (options = {}) ->
        options.input = @
        new RadioButton(options)
        return @