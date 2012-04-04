define ['jquery'], ($) ->
    class ToolTip
        constructor: (options = {}) ->
            @message = options.message ? null
            @parentElement = $(options.parent)
            @type = options.type ? 'info'
            @render();
            @onMouseMoveHandler = event =>
                x = Event.pointerX(event) + 10
                y = Event.pointerY(event) + 10
                @show(x, y)
            @parentElement.observe("mousemove", @onMouseMoveHandler)
            @onMouseOutHandler = event => @hide()
            @parentElement.observe("mouseout", @onMouseOutHandler)

        render : ->
            toolTipId = "#{@parentElement.id}_tooltip"
            html = []
            html.push "<div id=\"#{toolTipId}\" class=\"my-tooltip my-tooltip-#{@type} shadow\" style=\"display:none\">"
            html.push "<div class=\"my-tooltip-inner\">"
            html.push @message
            html.push "</div>"
            html.push "</div>"
            document.body.insert(html.join(""))
            @tooltip = $(toolTipId)

        show : (x, y) ->
            @tooltip.setStyle({
                position: 'absolute'
                top : y + 'px'
                left: x + 'px'
            })
            @tooltip.show();

        hide: ->
            @tooltip.hide()

        remove : ->
            Event.stopObserving(this.parentElement, "mousemove", @onMouseMoveHandler)
            Event.stopObserving(this.parentElement, "mouseout", @onMouseOutHandler)
            try
                @tooltip.remove()
            catch e
                # ignored