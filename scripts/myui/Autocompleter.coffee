define ['jquery', 'cs!myui/TextField'], ($, TextField) ->
  Event =
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

  class Autocompleter extends TextField
      constructor : (options) ->
          @baseInitialize(options)

      baseInitialize : (options) ->
          super(options)
          @element = $(options.input);
          @hasFocus = false;
          @changed = false;
          @active = false;
          @index = 0;
          @entryCount = 0;

          @options.items = null unless @options.items
          @options.listId = null unless @options.listId
          @options.tokens = [] unless @options.tokens
          @options.frequency = 0.4 unless @options.frequency
          @options.minChars = 2 unless @options.minChars
          @options.url = null unless @options.url
          @options.parameters = {} unless @options.parameters
          @options.finderParamName = 'find' unless @options.finderParamName
          @options.listTextPropertyName = 'text' unless @options.listTextPropertyName
          @options.listValuePropertyName = 'value' unless @options.listValuePropertyName
          @options.height = null unless @options.height
          @options.indicator = null unless @options.indicator
          @options.autoSelect = false unless @options.autoSelect
          @options.choices = 10 unless @options.choices
          @options.partialSearch = true unless @options.partialSearch
          @options.partialChars = 1 unless @options.partialChars
          @options.ignoreCase = true unless @options.ignoreCase
          @options.fullSearch = false unless @options.fullSearch
          @options.getParameters = null unless @options.getParameters

          unless @options.decorate
              @options.decorate = => @decorate(@element)

          unless @options.onShow
              @options.onShow = (element, update) =>
                  $(update).css('position', 'absolute')
                  p = $(element).offset()
                  vh = $(window).height() #view port height
                  vst = $(window).scrollTop() # view port scrolling top
                  rh = vh + vst - p.top - $(element).outerHeight() #remaining height
                  uh = (@entryCount * 22) + 6
                  offsetTop = p.top
                  offsetLeft = p.left
                  scrollTop = 0
                  if @tableGrid
                      scrollTop = @tableGrid.bodyDiv.scrollTop
                  topPos = $(element).outerHeight() + offsetTop - scrollTop
                  scrollLeft = 0
                  if @tableGrid
                      scrollLeft = @tableGrid.bodyDiv.scrollLeft
                  leftPos = offsetLeft - scrollLeft
                  if (rh >= (p.top - vst))  # down
                      if (uh > rh) then uh = rh - 10
                      update.css({
                          top : topPos + 'px',
                          left : leftPos + 'px',
                          width : (@elementWidth - 2) + 'px',
                          height: uh + 'px'
                      })
                  else  # above
                      if (uh > (p.top - vst))
                          uh = p.top - vst - 10;
                          topPos = p.top - (uh + scrollTop + 4)
                      else if (uh > rh)
                          topPos = p.top - (uh + scrollTop + 4)
                      update.css({
                          top : topPos + 'px',
                          left : leftPos + 'px',
                          width : (@elementWidth - 2) + 'px',
                          height: uh + 'px'
                      })
                  $(update).show()

          unless @options.onHide
              @options.onHide = (element, update) =>
                  $(update).hide()
                  @hasFocus = false
                  @active = false


          unless @options.selector
              @options.selector = =>
                  result = [] # Beginning matches
                  partial = [] # Inside matches
                  entry = @getToken()
                  items = @options.items
                  listTextPropertyName = @options.listTextPropertyName
                  listValuePropertyName = @options.listValuePropertyName
                  text = ''
                  value = ''
                  i = 0

                  while i < items.length and result.length < @options.choices
                      if typeof(items[i]) is 'object'
                          text = items[i][listTextPropertyName]
                          value = items[i][listValuePropertyName]
                      else
                          text = items[i]
                          value = items[i]

                      if @options.ignoreCase
                          foundPos = text.toLowerCase().indexOf(entry.toLowerCase())
                      else
                          foundPos = text.indexOf(entry)

                      while foundPos isnt -1
                          if foundPos is 0 and text.length isnt entry.length
                              result.push('<li id="' + value + '"><strong>' + text.substr(0, entry.length) + '</strong>' + text.substr(entry.length) + '</li>')
                              break
                          else if entry.length >= @options.partialChars and @options.partialSearch and foundPos isnt -1
                              if @options.fullSearch or /\s/.test(text.substr(foundPos - 1, 1))
                                  partial.push('<li>' + text.substr(0, foundPos) + '<strong>' + text.substr(foundPos, entry.length) + '</strong>' + text.substr(foundPos + entry.length) + '</li>')
                                  break
                          if @options.ignoreCase
                              foundPos = text.toLowerCase().indexOf(entry.toLowerCase(), foundPos + 1)
                          else
                              foundPos = text.indexOf(entry, foundPos + 1)
                      #end while
                      i++
                  #end while
                  if partial.length
                      result = result.concat(partial.slice(0, @options.choices - result.length));
                  return "<ul>" + result.join('') + "</ul>"

          if typeof(@options.tokens) is 'string'
              @options.tokens = new Array(@options.tokens)

          # Force carriage returns as token delimiters anyway
          unless '\n' in @options.tokens
              @options.tokens.push '\n'

          @observer = null
          if @element then @render(@element)

      render : (input) ->
          super(input)
          @element = $(input)
          @id = @element.attr('id')
          @oldElementValue = @element.val()
          @elementWidth = @element.width()
          @options.paramName ?= @element.name;
          @element.attr('autocomplete', 'off');
          @options.decorate();
          @container = $('#' + @id + '_container');
          @onBlurHandler = (event) => @onBlur(event)
          $(document).click @onBlurHandler
          @onKeyPressHandler = (event) => @_onKeyPress(event)
          @element.keydown @onKeyPressHandler

      show : ->
          @options.onShow @element, @update

      onFocus : (event) ->
          super(event)
          @tokenBounds = null

      getItems : ->
          return @options.items

      getUpdatedChoices : ->
          unless @update
              $(document.body).append('<div id="'+@id+'_update" class="my-autocompleter-list shadow"></div>')
              @update = $('#' + @id + '_update')

          if @options.url
              parameters = @options.parameters;
              parameters[@options.finderParamName] = @getToken()
              if @options.getParameters
                  moreParams = @options.getParameters()
                  for p of moreParams
                      parameters[p] = moreParams[p]

              @startIndicator();
              $.ajax(@options.url, {
                  complete: (response) =>
                      @options.items = $.parseJSON(response.responseText)
                      @stopIndicator()
                      @updateChoices @options.selector()
                  ,
                  dataType : 'json',
                  parameters: parameters
              })
          else
              @updateChoices @options.selector()

      onBlur : (event) ->
          target = $(event.target)
          ancestor = @container;
          blurFlg = true;
          if target.closest(ancestor).length > 0 then blurFlg = false # is descendant of ?
          if blurFlg
              @hide()
              @hasFocus = false
              @active = false

      decorate : (element) ->
          width = $(element).width()
          height = $(element).height()
          $(element).css({width: (width - 8) + 'px'})
          $(element).wrap('<div></div>') # auto complete container
          container = $(element).parent()
          container.addClass('my-autocompleter')
          container.attr('id', @id + '_container')
          container.css({width : width + 'px', height: height + 'px'})

      hide : ->
          @stopIndicator()
          if @update
              @update.remove()
              @active = false
              @hasFocus = false
              @update = null

      startIndicator : ->
          if @options.indicator then $(@options.indicator).show()


      stopIndicator : ->
          if @options.indicator then $(@options.indicator).hide()

      _onKeyPress: (event) ->
          if @active
              switch event.keyCode
                  when Event.KEY_TAB, Event.KEY_RETURN
                      @selectEntry()
                      event.stopPropagation()
                  when Event.KEY_ESC
                      @hide()
                      @active = false
                      event.stopPropagation()
                      return
                  when Event.KEY_LEFT, Event.KEY_RIGHT
                      return false
                  when Event.KEY_UP
                      @markPrevious()
                      @_renderList()
                      event.stopPropagation()
                      return
                  when Event.KEY_DOWN
                      @markNext()
                      @_renderList()
                      event.stopPropagation()
                      return
          else if event.keyCode is Event.KEY_TAB or
                  event.keyCode is Event.KEY_RETURN or
                  event.keyCode is Event.KEY_DOWN or
                  ($.browser.WebKit and event.keyCode is 0)
              return false

          @changed = true
          @hasFocus = true

          clearTimeout @observer if @observe
          onObserverEventHandler = => @onObserverEvent()
          @observer = setTimeout(onObserverEventHandler, @options.frequency * 1000)
          return true

      activate : ->
          @changed = false
          @hasFocus = true
          @getUpdatedChoices()

      onHover : (event) ->
          element = $(event.target).closest('LI')[0]
          if @index isnt $(element).data('autocompleteIndex')
              @index = $(element).data('autocompleteIndex')
              @_renderList()

      onClick : (event) ->
          element = $(event.target).closest('LI')[0]
          @index = $(element).data('autocompleteIndex')
          @selectEntry()
          @hide()

      _renderList : ->
          if @index is undefined then @index = 0
          if @entryCount > 0
              for i in [0...@entryCount]
                  if @index is i
                      $(@_getEntry(i)).addClass('selected')
                  else
                      $(@_getEntry(i)).removeClass('selected')
              if @hasFocus
                  @show()
                  @active = true
          else
              @active = false
              @hide()


      _getEntry : (index) ->
          return $('LI', @update)[index]

      markPrevious : ->
          if @index > 0
              @index--;
          else
              @index = @entryCount - 1;
          @_syncScroll(@_getEntry(@index), false)

      markNext : ->
          if @index < @entryCount - 1
              @index++
          else
              @index = 0
          @_syncScroll(@_getEntry(@index), true)

      _syncScroll : (entry, bottomFlg) ->
          updateHeight = @update.height()
          scrollTop = @update.scrollTop() # TODO check this
          if entry.offsetTop > scrollTop and entry.offsetTop < (scrollTop + updateHeight - 10)
              return
          unless bottomFlg
              @update.scrollTop(entry.offsetTop)
          else
              @update.scrollTop(entry.offsetTop - (updateHeight - $(entry).height() - 5))

      getCurrentEntry : ->
          return @_getEntry(@index)

      selectEntry : ->
          @updateElement(@getCurrentEntry())

      getValue : ->
          return @oldElementValue

      updateElement : (selectedElement) ->
          # if an updateElement method is provided
          if @options.updateElement
              @options.updateElement(selectedElement)
              return

          value = $(selectedElement).not('informal').text()

          bounds = @getTokenBounds()

          if bounds[0] isnt -1
              newValue = @element.val().substr(0, bounds[0])
              whitespace = @element.val().substr(bounds[0]).match(/^\s+/)
              if (whitespace)
                  newValue += whitespace[0]
              @element.val(newValue + value + @element.val().substr(bounds[1]))
          else
              @element.val(value)

          @oldElementValue = @element.val()
          @element.val(value)
          @oldElementValue = @element.val()
          @validate()
          @element.focus()
          if (@options.afterUpdate)
              @options.afterUpdate(@element, selectedElement)

      updateChoices : (choices) ->
          if !@changed && @hasFocus
              @update.html(choices)
              i = 0
              entries = $('LI', @update)
              @entryCount = entries.length
              @addObservers(entries)

              @stopIndicator()
              if @index is undefined then @index = 0

              if @entryCount is 1 and @options.autoSelect
                  @selectEntry()
                  @hide()
              else
                  @_renderList()


      addObservers : (entries) ->
          entries.mouseover (event) => @onHover(event)
          entries.click (event) => @onClick(event)
          entries.each (index, entry) ->
              $(entry).data('autocompleteIndex', index)

      onObserverEvent : ->
          @changed = false
          @tokenBounds = null
          if @getToken().length >= @options.minChars
              @getUpdatedChoices()
          else
              @active = false
              @hide()

          @oldElementValue = @element.val()

      getToken : ->
          bounds = @getTokenBounds()
          return $.trim(@element.val().substring(bounds[0], bounds[1]))

      getTokenBounds : ->
          return @tokenBounds if @tokenBounds
          value = @element.val()
          if $.trim(value) is '' then return [-1, 0]
          diff = @getFirstDifferencePos(value, @oldElementValue)
          offset = if diff is @oldElementValue.length then 1 else 0
          prevTokenPos = -1
          nextTokenPos = value.length
          index = 0
          l = @options.tokens.length
          while (index < l)
              tp = value.lastIndexOf(@options.tokens[index], diff + offset - 1)
              if tp > prevTokenPos then prevTokenPos = tp
              tp = value.indexOf(@options.tokens[index], diff + offset)
              if -1 != tp && tp < nextTokenPos then nextTokenPos = tp
              ++index
          return (@tokenBounds = [prevTokenPos + 1, nextTokenPos])

      getFirstDifferencePos : (newS, oldS) ->
          boundary = Math.min(newS.length, oldS.length)
          for index in [0...boundary] #TODO check this
              if newS[index] isnt oldS[index]
                  return index
          return boundary


      getSelectedValue : (text) ->
          items = @options.items
          listTextPropertyName = @options.listTextPropertyName
          listValuePropertyName = @options.listValuePropertyName
          result = text

          for item of items
              # This check prevents the case when items is just an array of strings
              if item instanceof Object
                  if item[listTextPropertyName] is text
                      result = item[listValuePropertyName]
                      break
              else
                  break
          return result
