define ['jquery', 'cs!myui/ToolTip', 'myui/i18n'], ($, ToolTip, i18n) ->
    class TextField
        constructor : (options = {}) ->
            @baseInitialize(options)
            if options.input?
                @render(options.input, true)


        baseInitialize : (options) ->
            @options = options
            @tableGrid = null
            @options.align = 'left' unless @options.align
            @options.required = false unless @options.required
            @options.validate = null unless @options.validate
            @options.initialText = null unless @options.initialText
            @options.tabIndex = null unless @options.tabIndex

        render : (input, flag = false) ->
            @input = $(input)
            @tooltip = null
            @id = $(input).attr('id')
            @options.name = @id unless @options.name?
            $(input).val(@options.initialText) if @options.initialText
            @reset()
            @options.align = 'right' if @options.type is 'number'
            @input.css('textAlign', @options.align)
            @input.attr('autocomplete', 'off');

            $(input).focus (event) => @onFocus(event)
            # registering validate handler
            $(input).blur => @validate()
            @decorate input if flag

        onFocus : ->
            @input.val('') if @options.initialText != null and @input.val() is $.trim(@options.initialText)

        decorate : (element) ->
            $(element).attr('tabIndex', @options.tabIndex) if @options.tabIndex?
            $(element).val @options.initialText if @options.initialText?
            width = $(element).width()
            height = $(element).height()
            $(element).css({width: (width - 8) + 'px'})
            $(element).wrap('<div></div>')
            @container = $(element).parent()
            @container.addClass('my-textfield-container')
            @container.attr('id', @id + '_container')
            @container.css({'width' : width + 'px', 'height': height + 'px'})

        reset : ->
            return unless @input?
            @input.removeClass('my-textfield-input-error') if @input
            @tooltip.remove() if @tooltip
            @input.unbind('blur')

        getValue : ->
            @input.val()

        setTableGrid: (tableGrid) ->
            @tableGrid = tableGrid

        validate : ->
            input = @input
            result = true
            if @required
                if $.trim(input.val()) is ''
                    input.addClass('my-textfield-input-error')
                    @tooltip = new ToolTip({
                        parent: input.parent(),
                        message : i18n.getMessage('error.required.field', {field : input.name}),
                        type: 'error'
                    })
                    return false
                else
                    input.removeClass('my-textfield-input-error')
                    @tooltip.remove() if (@tooltip)

            if @options.validate
                errors = []
                unless @options.validate(@getValue(), errors)
                    input.addClass('my-textfield-input-error')
                    if (errors.length > 0)
                        @tooltip = new ToolTip({
                            parent: input.parent(),
                            message : errors.pop(),
                            type: 'error'
                        });
                    return false;
                else
                    input.removeClass('my-textfield-input-error')
                    @tooltip.remove() if (this.tooltip)

            return result
