define ['jquery'], ($) ->
    class ToolTip
        constructor: (options = {}) ->
            @message = options.message ? null
            @parentElement = $(options.parent)
            @type = options.type ? 'info'
            @render()
            @parentElement.mouseout => @hide()
            @parentElement.mousemove (event) =>
                x = event.pageX + 10
                y = event.pageY + 10
                @show(x, y)

        render : ->
            id = @parentElement.attr('id')
            toolTipId = "#{id}_tooltip"
            html = []
            html.push "<div id=\"#{toolTipId}\" class=\"my-tooltip my-tooltip-#{@type}\" style=\"display:none\">"
            html.push "<div class=\"tooltip-inner\">"
            html.push @message
            html.push "</div>"
            html.push "</div>"
            $(document.body).append(html.join(""))
            @tooltip = $('#'+toolTipId)

        show : (x, y) ->
            @tooltip.css({
                position: 'absolute'
                top : y + 'px'
                left: x + 'px'
            })
            @tooltip.show();

        hide: ->
            @tooltip.hide()

        remove : ->
            @parentElement.unbind 'mousemove'
            @parentElement.unbind 'mouseout'
            try
                @tooltip.remove()
            catch e
                # ignored