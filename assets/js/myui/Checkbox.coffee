Checkbox = (($) ->
    class Checkbox
        constructor : (options) ->
            @elements = $(options.input)
            @options = $.extend({
                onClick : null,
                getValueOf : null,
                selectable : null
            }, options or {})
            @onClick = options.onClick
            @getValueOf = options.getValueOf
            @selectable = options.selectable
            @_decorate()
            @_addBehavior()

        _decorate : ->
            @elements.wrap('<label><div class="my-checkbox"></div></label>')
            $(element).parent('div').addClass('active') for element in @elements when $(element).is(':checked')
            @elements.append('<div></div>')

        _addBehavior : ->
            div = @elements.parent('div')
            div.on 'mousedown', (event) =>
                element = $(event.target)
                isChecked = $('input', element).is(':checked')
                if isChecked
                    element.removeClass('active')
                else
                    element.addClass('active')
                @options.onClick(!isChecked, $(element)) if @options.onClick?

    $.fn.myCheckbox = (options = {}) ->
        options.input = @
        new Checkbox(options)
        return @
) jQuery