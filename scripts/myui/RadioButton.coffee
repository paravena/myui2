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
            @elements.wrap('<label><span class="my-radio"></span></label>')
            $(element).parent('span').addClass('my-radio-checked') for element in @elements when $(element).is(':checked')

        _addBehavior : ->
            span = @elements.parent('span')
            span.on 'mousedown', (event) =>
                element = $(event.target)
                isChecked = $('input', element).is(':checked')
                name = $('input', element).attr('name')
                unless isChecked
                    $('input[name='+name+']').parent('span').removeClass('my-radio-checked')
                    element.addClass('my-radio-checked')
                @options.onClick(!isChecked, $(element)) if @options.onClick?

    $.fn.myRadioButton = (options = {}) ->
        options.input = @
        new RadioButton(options)
        return @