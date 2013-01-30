define ['jquery'], ($) ->
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
            @elements.wrap('<label><span class="my-checkbox"></span></label>')
            $(element).parent('span').addClass('my-checkbox-checked') for element in @elements when $(element).is(':checked')

        _addBehavior : ->
            span = @elements.parent('span')
            span.on 'mousedown', (event) =>
                element = $(event.target)
                isChecked = $('input', element).is(':checked')
                if isChecked
                    element.removeClass('my-checkbox-checked')
                else
                    element.addClass('my-checkbox-checked')
                @options.onClick(!isChecked, $(element)) if @options.onClick?

    $.fn.myCheckbox = (options = {}) ->
        options.input = @
        new Checkbox(options)
        return @