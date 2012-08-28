define ['jquery', 'jquerypp.custom', 'cs!myui/Util', 'cs!myui/KeyTable', 'cs!myui/TextField', 'cs!myui/BrowseInput', 'cs!myui/Autocompleter', 'cs!myui/ComboBox', 'cs!myui/DatePicker', 'myui/i18n'], ($, jquerypp, Util, KeyTable, TextField, BrowseInput, Autocompleter, ComboBox, DatePicker, i18n) ->
    class TableGrid
        ###
        # TableGrid constructor
        ###
        constructor : (tableModel) ->
            @_mtgId = $('.my-tablegrid').length + 1
            @tableModel = tableModel
            @columnModel = tableModel.columnModel or []
            @rows = tableModel.rows or []
            @name = tableModel.name or ''

            @options = $.extend({
                cellHeight : 24,
                pager : null
                sortColumnParameter : 'sortColumn',
                ascDescFlagParameter : 'ascDescFlg',
                onCellFocus : null,
                onCellBlur : null,
                onPageChange : null,
                afterRender : null,
                onFailure : null,
                rowStyle : ( ->  return ''),
                rowClass : ( ->  return ''),
                addSettingBehavior : true,
                addDraggingBehavior : true,
                addLazyRenderingBehavior : true,
                addNewRowsToEndBehaviour : false
            }, tableModel.options or {})

            @pagerHeight = 24
            @titleHeight = 24
            @toolbarHeight = 24
            @scrollBarWidth = 18
            @topPos = 0
            @leftPos = 0
            @selectedHCIndex = 0
            @pager = @options.pager
            @pager.pageParameter = @options.pager.pageParameter or 'page' if @options.pager?
            @url = tableModel.url or null
            @request = tableModel.request or {}
            @sortedColumnIndex = 0
            @sortedAscDescFlg = 'ASC' # or 'DESC'
            @modifiedRows = [] #will contain the modified row numbers
            @renderedRows = 0 #Use for lazy rendering
            @renderedRowsAllowed = 0 #Use for lazy rendering depends on bodyDiv height
            @newRowsAdded = []
            @deletedRows = []
            @options.addLazyRenderingBehavior = false if @options.addNewRowsToEndBehaviour
            # Header builder
            @hb = new HeaderBuilder(@_mtgId, @columnModel)
            if @hb.getHeaderRowNestedLevel() > 1
                @options.addSettingBehavior = false
                @options.addDraggingBehavior = false

            @headerWidth = @hb.getTableHeaderWidth()
            @headerHeight = @hb.getTableHeaderHeight()
            @columnModel = @hb.getLeafElements()
            for i in [0...@columnModel.length]
                @columnModel[i].editor = new TextField() if !@columnModel[i].hasOwnProperty('editor')
                if !@columnModel[i].hasOwnProperty('editable')
                    @columnModel[i].editable = false
                    @columnModel[i].editable = true if @columnModel[i].editor == 'checkbox' or @columnModel[i].editor instanceof TableGrid.CellCheckbox or @columnModel[i].editor == 'radio' or @columnModel[i].editor instanceof TableGrid.CellRadioButton
                @columnModel[i].visible = true if !@columnModel[i].hasOwnProperty('visible')
                @columnModel[i].sortable= true if !@columnModel[i].hasOwnProperty('sortable')
                @columnModel[i].type = 'string' if !@columnModel[i].hasOwnProperty('type')
                @columnModel[i].selectAllFlg = false if !@columnModel[i].hasOwnProperty('selectAllFlg')
                @columnModel[i].sortedAscDescFlg = 'DESC' if !@columnModel[i].hasOwnProperty('sortedAscDescFlg')
                @columnModel[i].positionIndex = i

            @targetColumnId = null
            @editedCellId = null

        ###
        # Displays TableGrid control.
        ###
        show : (target) ->
            @render(target)

        ###
        # Renders the table grid control into a given target.
        ###
        render : (target) ->
            @target = target
            $(target).html(@_createTableLayout())
            id = @_mtgId
            @tableDiv = $('#myTableGrid' + id)
            @headerTitle = $('#mtgHeaderTitle'+id)
            @headerToolbar = $('#mtgHeaderToolbar'+id)
            @headerRowDiv = $('#headerRowDiv' + id)
            @bodyDiv = $('#bodyDiv' + id)
            @overlayDiv = $('#overlayDiv' + id)
            @innerBodyDiv = $('#innerBodyDiv' + id)
            @pagerDiv = $('#pagerDiv' + id)
            @resizeMarkerLeft = $('#resizeMarkerLeft' + id)
            @resizeMarkerRight = $('#resizeMarkerRight' + id)
            @dragColumn = $('#dragColumn' + id)
            @colMoveTopDiv = $('#mtgColMoveTop' + id)
            @colMoveBottomDiv = $('#mtgColMoveBottom' + id)
            @scrollLeft = 0
            @scrollTop = 0
            @targetColumnId = null
          
            @bodyDiv.bind 'dom:dataLoaded', =>
                @_showLoaderSpinner()
                @bodyTable = $('#mtgBT' + id)
                @_applyCellCallbacks()
                @_applyHeaderButtons()
                @_makeAllColumnsResizable()
                @_makeAllColumnDraggable() if @options.addDraggingBehavior
                @_applySettingMenuBehavior() if @options.addSettingBehavior
                @keys = new KeyTable(@) # TODO verify if this is correct
                @_addKeyBehavior()
                @_addPagerBehavior() if @pager
                @options.afterRender() if @options.afterRender?
                @_hideLoaderSpinner()
          
            setTimeout(( =>
                @renderedRowsAllowed = Math.floor((@bodyHeight - @scrollBarWidth - 3)  / @options.cellHeight) + 1
                if @tableModel.hasOwnProperty('rows')
                    @innerBodyDiv.html(@_createTableBody(@rows))
                    @pagerDiv.html(@_updatePagerInfo()) if @pager
                    @bodyDiv.trigger 'dom:dataLoaded'
                else
                    @_retrieveDataFromUrl(1, true)
            ), 0)

            @options.toolbar = @options.toolbar or null
          
            if @options.toolbar?
                elements = @options.toolbar.elements or []
                if elements.indexOf(TableGrid.ADD_BTN) >= 0
                    $('#mtgAddBtn'+id).on 'click', =>
                        addFlg = true
                        if @options.toolbar.onAdd?
                            addFlg = @options.toolbar.onAdd()
                            addFlg = true if addFlg is undefined

                        if @options.toolbar.beforeAdd?
                            addFlg = @options.toolbar.beforeAdd()
                            addFlg = true if addFlg is undefined
                        
                        if addFlg
                            @addNewRow()
                            @options.toolbar.afterAdd() if @options.toolbar.afterAdd?
              
                if elements.indexOf(TableGrid.DEL_BTN) >= 0
                    $('#mtgDelBtn'+id).on 'click', =>
                        deleteFlg = true
                        if @options.toolbar.onDelete?
                            deleteFlg = @options.toolbar.onDelete()
                            deleteFlg = true if deleteFlg is undefined

                        if @options.toolbar.beforeDelete?
                            deleteFlg = @options.toolbar.beforeDelete()
                            deleteFlg = true if deleteFlg is undefined

                        if deleteFlg
                            @deleteRows()
                            @options.toolbar.afterDelete() if @options.toolbar.afterDelete

                if elements.indexOf(TableGrid.SAVE_BTN) >= 0
                    $('#mtgSaveBtn'+id).on 'click', =>
                        @_blurCellElement(@keys._nCurrentFocus)
                        @options.toolbar.onSave() if @options.toolbar.onSave?
            
            # Adding scrolling handler
            @bodyDiv.bind 'scroll', => @_syncScroll()
            # Adding resize handler
            $(window).bind 'resize', => @resize()

        ###
        # Creates the table layout
        ###
        _createTableLayout : ->
            target = $(@target)
            width = @options.width or (target.width() - @_fullPadding(target,'left') - @_fullPadding(target,'right')) + 'px'
            height = @options.height or (target.height() - @_fullPadding(target,'top') - @_fullPadding(target,'bottom') + 2) + 'px'
            id = @_mtgId
            overlayTopPos = 0
            overlayHeight = 0
            @tableWidth = parseInt(width) - 2
            overlayHeight = @tableHeight = parseInt(height) - 2

            idx = 0
            html = []
            html[idx++] = '<div id="myTableGrid'+id+'" class="my-tablegrid" style="position:relative;width:'+@tableWidth+'"px;height:'+@tableHeight+'px;z-index:0">'

            if @options.title? # Adding header title
                html[idx++] = '<div id="mtgHeaderTitle'+id+'" class="my-tablegrid-header-title" style="position:absolute;top:'+@topPos+'px;left:'+@leftPos+'px;width:'+(@tableWidth - 6)+'px;height:'+(@titleHeight - 6)+'px;padding:3px;z-index:10">'
                html[idx++] = @options.title
                html[idx++] = '</div>'
                @topPos += @titleHeight + 1


            if @options.toolbar? # adding toolbar
                elements = @options.toolbar.elements or []
                html[idx++] = '<div id="mtgHeaderToolbar'+id+'" class="my-tablegrid-toolbar" style="position:absolute;top:'+@topPos+'px;left:'+@leftPos+'px;width:'+(@tableWidth - 4)+'px;height:'+(@toolbarHeight - 2)+'px;padding:1px 2px;z-index:10">'
                beforeFlg = false
                if elements.indexOf(TableGrid.SAVE_BTN) >= 0
                    html[idx++] = '<a class="toolbar-button" id="mtgSaveBtn'+id+'"><span class="icon save-button">&nbsp;</span><span class="text">'+i18n.getMessage('label.save')+'</span></a>'
                    beforeFlg = true

                if elements.indexOf(TableGrid.ADD_BTN) >= 0
                    html[idx++] = '<div class="toolbar-separator">&#160;</div>' if beforeFlg
                    html[idx++] = '<a class="toolbar-button" id="mtgAddBtn'+id+'"><span class="icon add-button">&nbsp;</span><span class="text">'+i18n.getMessage('label.add')+'</span></a>'
                    beforeFlg = true

                if elements.indexOf(TableGrid.DEL_BTN) >= 0
                    html[idx++] = '<div class="toolbar-separator">&#160;</div>' if beforeFlg
                    html[idx++] = '<a class="toolbar-button" id="mtgDelBtn'+id+'"><span class="icon delete-button">&nbsp;</span><span class="text">'+i18n.getMessage('label.delete')+'</span></a>'

                html[idx++] = '</div>'
                @topPos += @toolbarHeight + 1

            overlayTopPos = @topPos
            # Adding Header Row
            html[idx++] = '<div id="headerRowDiv'+id+'" class="my-tablegrid-header-row" style="position:absolute;top:'+@topPos+'px;left:'+@leftPos+'px;width:'+@tableWidth+'px;height:'+@headerHeight+'px;padding:0;overflow:hidden;z-index:0">'
            #header row box useful for drag and drop

            html[idx++] = '<div id="mtgHRB'+id+'" style="position:relative;padding:0;margin:0;width:'+(@headerWidth+21)+'px;height:'+@headerHeight+'px;">'
            # Adding Header Row Cells
            html[idx++] = @hb._createHeaderRow()
            html[idx++] = '</div>' # closes mtgHRB
            html[idx++] = '</div>' # closes headerRowDiv
            @topPos += @headerHeight + 1

            # Adding Body Area
            @bodyHeight = @tableHeight - @headerHeight - 3
            @bodyHeight = @bodyHeight - @titleHeight - 1 if @options.title?
            @bodyHeight = @bodyHeight - @pagerHeight - 1 if @options.pager?
            @bodyHeight = @bodyHeight - @toolbarHeight - 1 if @options.toolbar?
            overlayHeight = @bodyHeight + @headerHeight

            html[idx++] = '<div id="overlayDiv'+id+'" class="overlay" style="position:absolute;top:'+overlayTopPos+'px;width:'+(@tableWidth+2)+'px;height:'+(overlayHeight+2)+'px;overflow:none;">'
            html[idx++] = '<div class="loadingBox" style="margin-top:'+((overlayHeight+2) / 2 - 14)+'px">'+i18n.getMessage('label.loading')+'</div>'
            html[idx++] = '</div>' # closes overlay
            html[idx++] = '<div id="bodyDiv'+id+'" class="my-tablegrid-body" style="position:absolute;top:'+@topPos+'px;left:'+@leftPos+'px;width:'+@tableWidth+'px;height:'+@bodyHeight+'px;overflow:auto;">'
            html[idx++] = '<div id="innerBodyDiv'+id+'" class="my-tablegrid-inner-body" style="position:relative;top:0px;width:'+(@tableWidth - @scrollBarWidth)+'px;overflow:none;">'
            html[idx++] = '</div>' # closes innerBodyDiv
            html[idx++] = '</div>' # closes bodyDiv

            # Adding Pager Panel
            if @pager?
                @topPos += @bodyHeight + 2
                html[idx++] = '<div id="pagerDiv'+id+'" class="my-tablegrid-pager" style="position:absolute;top:'+@topPos+'px;left:0;bottom:0;width:'+(@tableWidth - 4)+'px;height:'+(@pagerHeight - 4)+'px">'
                html[idx++] = @_updatePagerInfo(true)
                html[idx++] = '</div>' # closes Pager Div

            # Adding Table Setting Button Control
            if @options.addSettingBehavior
                html[idx++] = '<div id="mtgSB'+id+'" class="my-tablegrid-setting-button" style="left:'+(@tableWidth - 20)+'px"><div class="icon">&nbsp;</div></div>'
                # Adding Table Setting Menu
                html[idx++] = @_createSettingMenu()

            # Adding Header Button Control
            html[idx++] = '<div id="mtgHB'+id+'" class="my-tablegrid-header-button" style="width:14px;height:'+@headerHeight+'px">'
            html[idx++] = '</div>'
            # Adding Header Button Menu
            html[idx++] = '<div id="mtgHBM'+id+'" class="my-tablegrid-menu shadow">'
            html[idx++] = '<ul>'
            html[idx++] = '<li>'
            html[idx++] = '<a id="mtgSortAsc'+id+'" class="my-tablegrid-menu-item" href="javascript:void(0)">'
            html[idx++] = '<table cellspacing="0" cellpadding="0" width="100%" border="0">'
            html[idx++] = '<tr><td width="25"><span class="my-tablegrid-menu-item-icon sort-ascending-icon">&nbsp;</span></td>'
            html[idx++] = '<td>'+i18n.getMessage('label.sortAsc')+'</td></tr></table>'
            html[idx++] = '</a>'
            html[idx++] = '</li>'
            html[idx++] = '<li>'
            html[idx++] = '<a id="mtgSortDesc'+id+'" class="my-tablegrid-menu-item" href="javascript:void(0)">'
            html[idx++] = '<table cellspacing="0" cellpadding="0" width="100%" border="0">'
            html[idx++] = '<tr><td width="25"><span class="my-tablegrid-menu-item-icon sort-descending-icon">&nbsp;</span></td>'
            html[idx++] = '<td>'+i18n.getMessage('label.sortDesc')+'</td></tr></table>'
            html[idx++] = '</a>'
            html[idx++] = '</li>'
            html[idx++] = '<li class="mtgSelectAll">'
            html[idx++] = '<a class="my-tablegrid-menu-item" href="javascript:void(0)">'
            html[idx++] = '<table cellspacing="0" cellpadding="0" width="100%" border="0">'
            html[idx++] = '<tr><td width="25"><span class="my-tablegrid-menu-item-checkbox"><input type="checkbox" id="mtgSelectAll'+id+'"></span></td>'
            html[idx++] = '<td>'+i18n.getMessage('label.selectAll')+'</td></tr></table>'
            html[idx++] = '</a>'
            html[idx++] = '</li>'
            html[idx++] = '</ul>'
            html[idx++] = '</div>'

            # Adding resize markers
            html[idx++] = '<div id="resizeMarkerLeft'+id+'" class="my-tablegrid-resize-marker">'
            html[idx++] = '</div>'
            html[idx++] = '<div id="resizeMarkerRight'+id+'" class="my-tablegrid-resize-marker">'
            html[idx++] = '</div>'

            # Adding Dragging controls
            html[idx++] = '<div id="mtgColMoveTop'+id+'" class="my-tablegrid-column-move-top">&nbsp;</div>'
            html[idx++] = '<div id="mtgColMoveBottom'+id+'" class="my-tablegrid-column-move-bottom">&nbsp;</div>'
          
            html[idx++] = '<div id="dragColumn'+id+'" class="dragColumn" style="width:100px;height:18px;">'
            html[idx++] = '<span class="columnTitle">&nbsp;</span>'
            html[idx++] = '<div class="drop-no">&nbsp;</div>'
            html[idx++] = '</div>'

            html[idx++] = '</div>' # closes Table Div;
            return html.join('')

        ###
        # Creates the Table Body
        ###
        _createTableBody : (rows) ->
            id = @_mtgId
            renderedRowsAllowed = @renderedRowsAllowed
            renderedRows = @renderedRows
            cellHeight = @options.cellHeight
            headerWidth = @headerWidth
            html = []
            idx = 0
            firstRenderingFlg = false
            if renderedRows == 0
                firstRenderingFlg = true
                renderedRowsAllowed = @renderedRowsAllowed = rows.length if !@options.addLazyRenderingBehavior

            if firstRenderingFlg
                @innerBodyDiv.css('height',  (rows.length * cellHeight) + 'px')
                html[idx++] = '<table id="mtgBT'+id+'" border="0" cellspacing="0" cellpadding="0" width="'+headerWidth+'" class="my-tablegrid-body-table">'
                html[idx++] = '<tbody>'

            lastRowToRender = renderedRows + renderedRowsAllowed
            lastRowToRender = rows.length if lastRowToRender > rows.length
            @_showLoaderSpinner()
            for i in [renderedRows...lastRowToRender]
                rows[i] = @_fromArrayToObject(rows[i])
                html[idx++] = @_createRow(rows[i], i)
                renderedRows++
          
            if firstRenderingFlg
                html[idx++] = '</tbody>'
                html[idx++] = '</table>'

            @renderedRows = renderedRows
            setTimeout ( => @_hideLoaderSpinner()), 1.5 #just to see the spinner
            return html.join('')

        ###
        # Creates a row
        ###
        _createRow : (row, rowIdx) ->
            id = @_mtgId
            tdTmpl = '<td id="mtgC{id}_c{x}r{y}" height="{height}" width="{width}" style="width:{width}px;height:{height}px;padding:0;margin:0;display:{display}" class="my-tablegrid-cell mtgC{id} mtgC{id}_c{x} mtgR{id}_r{y}">'
            icTmpl = '<div id="mtgIC{id}_c{x}r{y}" style="width:{width}px;height:{height}px;padding:3px;text-align:{align}" class="my-tablegrid-inner-cell mtgIC{id} mtgIC{id}_c{x} mtgIR{id}_r{y}">'
            checkboxTmpl = '<input id="mtgInput{id}_c{x}r{y}" name="mtgInput{id}_c{x}r{y}" type="checkbox" value="{value}" class="mtgInput{id}_c{x} mtgInputCheckbox" checked="{checked}">'
            radioTmpl = '<input id="mtgInput{id}_c{x}r{y}" name="mtgInput{id}_c{x}" type="radio" value="{value}" class="mtgInput{id}_c{x} mtgInputRadio">'
            if $.browser.opera or $.browser.webkit # TODO review this issue
                checkboxTmpl = '<input id="mtgInput{id}_c{x}r{y}" name="mtgInput{id}_c{x}r{y}" type="checkbox" value="{value}" class="mtgInput{id}_c{x}" checked="{checked}">'
                radioTmpl = '<input id="mtgInput{id}_c{x}r{y}" name="mtgInput{id}_c{x}" type="radio" value="{value}" class="mtgInput{id}_c{x}">'

            rs = @options.rowStyle # row style handler
            rc = @options.rowClass # row class handler
            cellHeight = @options.cellHeight
            iCellHeight = cellHeight - 6
            cm = @columnModel
            html = []
            idx = 0
            html[idx++] = '<tr id="mtgRow'+id+'_r'+rowIdx+'" class="mtgRow'+id+' '+rc(rowIdx)+'" style="'+rs(rowIdx)+'">'
            for j in [0...cm.length]
                columnId = cm[j].id
                type = cm[j].type or 'string'
                cellWidth = parseInt(cm[j].width) # consider border at both sides
                iCellWidth = cellWidth - 6 # consider padding at both sides
                editor = cm[j].editor or null
                normalEditorFlg = !(editor == 'checkbox' or editor instanceof TableGrid.CellCheckbox or editor == 'radio' or editor instanceof TableGrid.CellRadioButton or editor instanceof ComboBox)
                alignment = 'left'
                display = '\'\''
                if !cm[j].hasOwnProperty('renderer')
                    if type == 'number'
                        alignment = 'right'
                    else if type == 'boolean'
                        alignment = 'center'

                alignment = cm[j].align if cm[j].hasOwnProperty('align')
                display = 'none' if !cm[j].visible
                temp = tdTmpl.replace(/\{id\}/g, id)
                temp = temp.replace(/\{x\}/g, j)
                temp = temp.replace(/\{y\}/g, rowIdx)
                temp = temp.replace(/\{width\}/g, cellWidth)
                temp = temp.replace(/\{height\}/g, cellHeight)
                temp = temp.replace(/\{display\}/g, display)
                html[idx++] = temp
                temp = icTmpl.replace(/\{id\}/g, id)
                temp = temp.replace(/\{x\}/g, j)
                temp = temp.replace(/\{y\}/g, rowIdx)
                temp = temp.replace(/\{width\}/, iCellWidth)
                temp = temp.replace(/\{height\}/, iCellHeight)
                temp = temp.replace(/\{align\}/, alignment)
                html[idx++] = temp
                if normalEditorFlg # checkbox is an special case
                    if !cm[j].hasOwnProperty('renderer')
                        html[idx++] = row[columnId]
                    else
                        html[idx++] = cm[j].renderer(row[columnId], @getRow(rowIdx))
                else if editor == 'checkbox' or editor instanceof TableGrid.CellCheckbox
                    temp = checkboxTmpl.replace(/\{id\}/g, id)
                    temp = temp.replace(/\{x\}/g, j)
                    temp = temp.replace(/\{y\}/g, rowIdx)
                    temp = temp.replace(/\{value\}/, row[columnId])
                    if editor.selectable is undefined or !editor.selectable
                        selectAllFlg = cm[j].selectAllFlg
                        if editor.hasOwnProperty('getValueOf')
                            trueVal = editor.getValueOf(true)
                            if row[columnId] == trueVal or selectAllFlg
                                temp = temp.replace(/\{checked\}/, 'checked')
                            else
                                temp = temp.replace(/checked=.*?>/, '')
                        else
                            if eval(row[columnId]) or selectAllFlg  #must be true or false
                                temp = temp.replace(/\{checked\}/, 'checked')
                            else
                                temp = temp.replace(/checked=.*?>/, '')
                    else # When is selectable
                        if cm[j].selectAllFlg
                            temp = temp.replace(/\{checked\}/, 'checked')
                        else
                            temp = temp.replace(/checked=.*?>/, '')

                    html[idx++] = temp
                else if (editor == 'radio' or editor instanceof TableGrid.CellRadioButton)
                    temp = radioTmpl.replace(/\{id\}/g, id)
                    temp = temp.replace(/\{x\}/g, j)
                    temp = temp.replace(/\{y\}/g, rowIdx)
                    temp = temp.replace(/\{value\}/, row[columnId])
                    html[idx++] = temp
                else if editor instanceof ComboBox
                    if !cm[j].hasOwnProperty('renderer')
                        listTextPropertyName = cm[j].editor.options.listTextPropertyName
                        listValuePropertyName = cm[j].editor.options.listValuePropertyName
                        cm[j].renderer = (value, list) ->
                            result = value
                            for i in [0...list.length]
                                if list[i] instanceof Object
                                    if list[i][listValuePropertyName] is value
                                        result = list[i][listTextPropertyName]
                                        break
                                else
                                    break # this happen when list is an array of strings
                            # end for
                            return result
                        # end renderer
                    html[idx++] = cm[j].renderer(row[columnId], editor.getItems(), @getRow(rowIdx))

                html[idx++] = '</div>'
                html[idx++] = '</td>'
            # end for
            html[idx++] = '</tr>'
            return html.join('')

        ###
        # Toggle loading overlay.
        ###
        _toggleLoadingOverlay : ->
            id = @_mtgId
            overlayDiv = $('#overlayDiv'+id)
            if overlayDiv.css('visibility') == 'hidden'
                @_hideMenus()
                overlayDiv.css('visibility', 'visible')
            else
                overlayDiv.css('visibility', 'hidden')

        ###
        # Applies cell callbacks.
        ###
        _applyCellCallbacks : ->
            renderedRows = @renderedRows
            renderedRowsAllowed = @renderedRowsAllowed
            beginAtRow = renderedRows - renderedRowsAllowed
            beginAtRow = 0 if beginAtRow < 0
            @_applyCellCallbackToRow(j) for j in [beginAtRow...renderedRows]

        ###
        # Apply callback to rows.
        ###
        _applyCellCallbackToRow : (y) ->
            id = @_mtgId
            cm = @columnModel
            for i in [0...cm.length]
                editor = cm[i].editor
                if (editor == 'radio' or editor instanceof TableGrid.CellRadioButton) or
                   (editor == 'checkbox' or editor instanceof TableGrid.CellCheckbox)
                    element = $('#mtgInput'+id + '_c' + i + 'r' + y)
                    innerElement = $('#mtgIC'+id + '_c' + i + 'r' + y)
                    unless editor.selectable
                        do (editor, element, innerElement) =>
                            element.on 'click', =>
                                elementId = element.attr('id')
                                match = elementId.match(/_c(\d*?)r(\d*?)/)
                                x = match[1];
                                y = match[2];
                                value = element.is(':checked')
                                value = editor.getValueOf(element.is(':checked')) if editor.getValueOf?
                                @setValueAt(value, x, y, false);
                                @modifiedRows.push(y) if y >= 0 and @modifiedRows.indexOf(y) == -1  # if doesn't exist in the array the row is registered
                    editor.onClickCallback(element.value, element.is(':checked')) if editor.onClickCallback?
                    innerElement.addClass('modified-cell') unless editor.selectable

        ###
        # Returns TableGrid id.
        ###
        getId : ->
            return @_mtgId

        ###
        # Displays loader spinner.
        ###
        _showLoaderSpinner : ->
            id = @_mtgId
            $('#mtgLoader'+id).show()

        ###
        # Hides loader spinner.
        ###
        _hideLoaderSpinner : ->
            id = @_mtgId
            $('#mtgLoader'+id).hide()

        ###
        # Hides menus.
        ###
        _hideMenus : ->
            id = @_mtgId
            $('#mtgHB'+id).css('visibility','hidden')
            $('#mtgHBM'+id).css('visibility','hidden')
            $('#mtgSM'+id).css('visibility','hidden')

        ###
        # Creates the Setting Menu.
        ###
        _createSettingMenu : ->
            id = @_mtgId
            cm = @columnModel
            bh = @bodyHeight + 30
            height = if cm.length * 25 > bh then bh else 0
            html = []
            idx = 0;
            if height > 0
                html[idx++] = '<div id="mtgSM'+id+'" class="my-tablegrid-menu shadow" style="height:'+height+'px">'
            else
                html[idx++] = '<div id="mtgSM'+id+'" class="my-tablegrid-menu shadow">'
            html[idx++] = '<ul>'
            for c in cm
                html[idx++] = '<li>' #TODO simplify this code, remove nested table
                html[idx++] = '<a href="#" class="my-tablegrid-menu-item">'
                html[idx++] = '<table border="0" cellpadding="0" cellspacing="0" width="100%">'
                if c.visible
                    html[idx++] = '<tr><td width="25"><span><input id="'+c.id+'" type="checkbox" checked="checked"></span></td>'
                else
                    html[idx++] = '<tr><td width="25"><span><input id="'+c.id+'" type="checkbox"></span></td>'
                html[idx++] = '<td><label for="'+c.id+'">&nbsp;'+ c.title+'</label></td></tr>'
                html[idx++] = '</table>'
                html[idx++] = '</a>'
                html[idx++] = '</li>'

            html[idx++] = '</ul>'
            html[idx++] = '</div>'
            return html.join('')

        ###
        # Applies Setting Menu behavior
        ###
        _applySettingMenuBehavior : ->
            id = @_mtgId
            cm = @columnModel
            settingMenu = $('#mtgSM' + id)
            settingButton = $('#mtgSB' + id)
          
            width = settingMenu.width()
          
            settingButton.on 'click', ->
                if settingMenu.css('visibility') == 'hidden'
                    topPos = settingButton.position().top
                    leftPos = settingButton.position().left
                    settingMenu.css({
                        'top' : (topPos + 16) + 'px',
                        'left' : (leftPos - width + 16) + 'px',
                        'visibility' : 'visible'
                    })
                else
                    settingMenu.css('visibility', 'hidden')

            miFlg = false
            settingMenu.on 'mouseenter', -> miFlg = true
            settingMenu.on 'mouseleave', (event) ->
                miFlg = false
                setTimeout ( ->
                    settingMenu.css('visibility', 'hidden') unless miFlg
                ), 500

            $('#mtgSM'+ id + ' :checkbox').on 'click', (event) =>
                checkbox = $(event.target)
                @_toggleColumnVisibility(checkbox.attr('id'))

        ###
        # Synchronizes horizontal scrolling
        ###
        _syncScroll : ->
            id = @_mtgId
            keys = @keys
            bodyDiv = @bodyDiv
            headerRowDiv = @headerRowDiv
            bodyTable = @bodyTable
            renderedRows = @renderedRows

            @scrollLeft = bodyDiv.scrollLeft()
            headerRowDiv.scrollLeft(bodyDiv.scrollLeft())
            @scrollTop = bodyDiv.scrollTop()

            $('#mtgHB' + id).css('visibility', 'hidden')

            if renderedRows < @rows.length and (bodyTable.height() - bodyDiv.scrollTop() - 10) < bodyDiv[0].clientHeight
                html = @_createTableBody(@rows)
                bodyTable.find('tbody').append(html)
                @_addKeyBehavior()
                @_applyCellCallbacks()

        ###
        # Makes all columns resizable
        ###
        _makeAllColumnsResizable : ->
            id = @_mtgId
            headerHeight = @headerHeight
            scrollBarWidth = @scrollBarWidth
            topPos = 0
            topPos += @titleHeight if @options.title
            topPos += @toolbarHeight if (@options.toolbar)
            columnIndex = 0
            leftPos = 0
            for separator in $('.mtgHS' + id)
                do (separator) =>
                    $(separator).on 'mousemove', =>
                        separatorId = $(separator).attr('id')
                        columnIndex = separatorId.match(/_c(\d*)/)[1] # extracts column index
                        if columnIndex >= 0
                            leftPos = $('#mtgHC' + id + '_c' + columnIndex).position().left - @scrollLeft
                            leftPos += $('#mtgHC' + id + '_c' + columnIndex).outerWidth() - 1
                            @resizeMarkerRight.css({
                                'height' : (@bodyHeight + headerHeight) + 'px',
                                'top' : (topPos + 2) + 'px',
                                'left' : leftPos + 'px'
                            })

            @resizeMarkerRight.on 'draginit', (event, drag) =>
                drag.horizontal()
                markerHeight = @bodyHeight + headerHeight + 2
                markerHeight = markerHeight - scrollBarWidth + 1 if @_hasHScrollBar()
                @resizeMarkerRight.css({
                    'height' : markerHeight + 'px',
                    'background-color' : 'dimgray'
                })

                leftPos = $('#mtgHC' + id + '_c' + columnIndex).position().left - @scrollLeft

                @resizeMarkerLeft.css({
                    'height' : markerHeight + 'px',
                    'top' : (topPos + 2) + 'px',
                    'left' : leftPos + 'px',
                    'background-color' : 'dimgray'
                })

            @resizeMarkerRight.on 'dragend', (event, drag) =>
                newWidth = @resizeMarkerRight.position().left - @resizeMarkerLeft.position().left
                @_resizeColumn(columnIndex, newWidth) if newWidth > 0 and columnIndex != null
                @resizeMarkerLeft.css({
                    'background-color' : 'transparent',
                    'left' : '0'
                })
                @resizeMarkerRight.css('background-color', 'transparent')

        ###
        # Resizes a column to a new size
        #
        # @param index the index column position
        # @param newWidth resizing width
        ###
        _resizeColumn: (index, newWidth) ->
            id = @_mtgId
            cm = @columnModel

            oldWidth = $('#mtgHC' + id + '_c' + index).width()
            editor = cm[index].editor
            checkboxOrRadioFlg = editor == 'checkbox' or editor instanceof TableGrid.CellCheckbox or editor == 'radio' or editor instanceof TableGrid.CellRadioButton

            $('#mtgHC' + id + '_c' + index).attr('width', newWidth)
            $('#mtgHC' + id + '_c' + index).css('width', newWidth + 'px')
            $('#mtgIHC' + id + '_c' + index).css('width', (newWidth - 8) + 'px')

            $('.mtgC' + id + '_c' + index).attr('width', newWidth)
            $('.mtgC' + id + '_c' + index).css('width', newWidth + 'px')

            for cell in $('.mtgIC' + id + '_c' + index)
                do (cell) =>
                    cellId = $(cell).attr('id')
                    y = cellId.match(/r(\d*)/)[1] # extracts row index
                    value = @getValueAt(index, y)
                    $(cell).css('width', (newWidth - 6) + 'px')
                    if !checkboxOrRadioFlg
                        if cm[index].renderer?
                            if editor instanceof ComboBox
                                value = cm[index].renderer(value, editor.getItems(), @getRow(y))
                            else
                                value = cm[index].renderer(value, @getRow(y))
                        $(cell).html(value)

            @headerWidth = @headerWidth - (oldWidth - newWidth)

            $('#mtgHRB' + id).css('width', (@headerWidth + 21) + 'px')
            $('#mtgHRT' + id).css('width', (@headerWidth + 21) + 'px')
            $('#mtgHRT' + id).attr('width', @headerWidth + 21)
            $('#mtgBT' + id).attr('width', @headerWidth)
            $('#mtgBT' + id).css('width', @headerWidth + 'px')

            @columnModel[index].width = newWidth
            @_syncScroll()

        ###
        # Has horizontal scroll bar?
        ###
        _hasHScrollBar : ->
            return @headerWidth + 20 > @tableWidth

        _scrollToRow : (rowIndex) ->
            return if @options.addLazyRenderingBehavior # This only works without lazy rendering
            cellHeight = @options.cellHeight
            bodyHeight = @bodyHeight
            scrollBarWidth = this.scrollBarWidth;
            scrollToPosition = rowIndex * (cellHeight + 1)
            # Is scrolling necessary?
            @bodyDiv.scrollTop(@scrollTop = scrollToPosition) if scrollToPosition > bodyHeight - scrollBarWidth - 3

        ###
        # Makes all columns draggable
        ###
        _makeAllColumnDraggable : ->
            id = @_mtgId
            topPos = 0
            columnIndex = -1
            topPos += @titleHeight if @options.title?
            topPos += @toolbarHeight if @options.toolbar?
            dragColumn = $('#dragColumn' + id)

            $('.mtgIHC' + id).on 'mouseenter', (event) =>
                column = $(event.target)
                leftPos = column.parent('th').position().left
                dragColumn.css({
                    'top' : (topPos + 15) + 'px',
                    'left' : (leftPos - @scrollLeft + 15) + 'px'
                })

            $('.mtgIHC' + id).on 'draginit', (event, drag) =>
                column = $(event.target)
                columnIndex = column.attr('id').match(/c(\d*)/)[1]
                dragColumn.find('span').html(column.text()).end().css('visibility', 'visible')
                drag.representative(dragColumn, dragColumn.width() / 2, 10)

            $('.mtgIHC' + id).on 'dragmove', (event, drag) =>
                leftPos = dragColumn.position().left
                width = dragColumn.width()
                @_detectDroppablePosition(leftPos + width / 2, width, dragColumn, columnIndex)

            $('.mtgIHC' + id).on 'dragend', (event, drag) =>
                dragColumn.css('visibility', 'hidden')
                @colMoveTopDiv.css('visibility', 'hidden')
                @colMoveBottomDiv.css('visibility', 'hidden')
                if columnIndex >= 0 and @targetColumnId >= 0
                    @_moveColumn(columnIndex, @targetColumnId)
                    columnIndex = -1

        ###
        # Detects droppable position when the mouse pointer is over a header cell
        # separator
        ###
        _detectDroppablePosition : (columnPos, width, dragColumn, index) ->
            topPos = -10
            topPos += @headerHeight if @options.title?
            topPos += @headerHeight if @options.toolbar?
            sepLeftPos = 0
            cm = @columnModel
            scrollLeft = @scrollLeft
            colMoveTopDiv = @colMoveTopDiv
            colMoveBottomDiv = @colMoveBottomDiv
          
            for i in [0...cm.length]
                sepLeftPos += parseInt(cm[i].width) + 2 if (cm[i].visible)
                if columnPos > (sepLeftPos - scrollLeft) and (columnPos - (sepLeftPos - @scrollLeft)) < (width / 2)
                    colMoveTopDiv.css({
                        'top' : topPos + 'px',
                        'left' : (sepLeftPos - scrollLeft - 4) + 'px',
                        'visibility' : 'visible'
                    })
                    colMoveBottomDiv.css({
                        'top' : (topPos + 34) + 'px',
                        'left' : (sepLeftPos - scrollLeft - 4) + 'px',
                        'visibility' : 'visible'
                    })
                    @targetColumnId = i
                    dragColumn.find('div').attr('class', if i != index then 'drop-yes' else 'drop-no')
                    break
                else
                    colMoveTopDiv.css('visibility', 'hidden')
                    colMoveBottomDiv.css('visibility', 'hidden')
                    @targetColumnId = null
                    dragColumn.find('div').attr('class','drop-no')

        ###
        # Moves a column from one position to a new one
        #
        # @param fromColumnId initial position
        # @param toColumnId target position
        ###
        _moveColumn : (fromColumnId, toColumnId) ->
            # Some validations
            return if fromColumnId == null or toColumnId == null or fromColumnId == toColumnId or (toColumnId + 1 == fromColumnId and fromColumnId == @columnModel.length -1)
          
            id = @_mtgId
            cm = @columnModel
            keys = @keys
            renderedRows = @renderedRows
            numberOfRowsAdded = @newRowsAdded.length
          
            $('#mtgHB' + id).css('visibility', 'hidden') # in case the cell menu button is visible
            @_blurCellElement(keys._nCurrentFocus) # in case there is a cell in editing mode
            keys.blur() # remove the focus of the selected cell
          
            removedHeaderCell = null
            targetHeaderCell = null
            removedCells = null
            tr = null
            targetId = null
            targetCell = null
            idx = 0
            i = 0
            last = null
          
            if toColumnId == 0  # moving to the left to first column
                removedHeaderCell = $('#mtgHC'+id+'_c'+fromColumnId).detach()
                targetHeaderCell = $('#mtgHC'+id+'_c'+ toColumnId)
                removedHeaderCell.insertBefore(targetHeaderCell)
                # Moving cell elements
                removedCells =  $('.mtgC' + id + '_c' + fromColumnId).detach()

                if numberOfRowsAdded > 0
                    for i in [-numberOfRowsAdded...0]
                        targetCell = $('#mtgC'+id+'_c'+toColumnId+'r'+i)
                        $(removedCells[i+numberOfRowsAdded]).insertBefore(targetCell)

                for i in [numberOfRowsAdded...(renderedRows+numberOfRowsAdded)]
                    targetCell = $('#mtgC'+id+'_c'+toColumnId+'r'+(i-numberOfRowsAdded))
                    $(removedCells[i]).insertBefore(targetCell)

            else if toColumnId > 0 and toColumnId < cm.length - 1 # moving in between
                removedHeaderCell = $('#mtgHC' + id + '_c' + fromColumnId).detach()
                targetId = toColumnId + 1
                targetId-- if targetId == fromColumnId
                targetHeaderCell = $('#mtgHC'+id+'_c'+ targetId)
                removedHeaderCell.insertBefore(targetHeaderCell)
                # Moving cell elements
                removedCells =  $('.mtgC' + id + '_c' + fromColumnId).detach()

                if numberOfRowsAdded > 0
                    for i in [-numberOfRowsAdded...0]
                        targetCell = $('#mtgC' + id + '_c' + targetId +'r' + i)
                        $(removedCells[i+numberOfRowsAdded]).insertBefore(targetCell)

                for i in [numberOfRowsAdded...(renderedRows+numberOfRowsAdded)]
                    targetCell = $('#mtgC' + id + '_c' + targetId + 'r' + (i-numberOfRowsAdded))
                    $(removedCells[i]).insertBefore(targetCell)

            else if toColumnId == cm.length - 1 # moving to the last column
                lastTh = $('#mtgHC' + id + '_c' + fromColumnId).parent('tr').find('th:last')
                removedHeaderCell = $('#mtgHC' + id + '_c' + fromColumnId).detach()
                removedHeaderCell.insertBefore(lastTh)

                # Moving cell elements
                removedCells = $('.mtgC' + id + '_c' + fromColumnId).detach()

                if (numberOfRowsAdded > 0)
                    for i in [-numberOfRowsAdded...0]
                        tr = $('#mtgRow' + id + '_r' + i)
                        tr.append(removedCells[i+numberOfRowsAdded])

                for i in [numberOfRowsAdded...(renderedRows+numberOfRowsAdded)]
                    tr = $('#mtgRow' + id + '_r' + (i-numberOfRowsAdded))
                    tr.append(removedCells[i])

            # Update column model
            columnModelLength = cm.length
            columnModelEntry = cm[fromColumnId]
            cm[fromColumnId] = null
            cm = $.map cm, (element) -> return element if element? # remove empty elements
            aTemp = []
            k = 0
            targetColumnId = toColumnId
            targetColumnId++ if toColumnId > 0 and toColumnId < fromColumnId
            targetColumnId-- if targetColumnId == fromColumnId
            for c in [0...columnModelLength]
                aTemp[k++] = columnModelEntry if c == targetColumnId
                aTemp[k++] = cm[c] if c < (columnModelLength - 1)
            cm = @columnModel = aTemp
            $('#mtgHRT'+id + ' th').each (index, th) ->
                if index < cm.length
                    $(th).attr('id', 'mtgHC'+ id + '_c' + index)
                    try
                        ihc = $(th).find('div.my-tablegrid-inner-header-cell')
                        ihc.attr('id', 'mtgIHC' + id + '_c' + index)
                        ihc.find('span').attr('id', 'mtgSortIcon' + id + '_c' + index)
                        hs = $(th).find('div.mtgHS')
                        hs.attr('id', 'mtgHS' + id + '_c' + index)
                    catch ihc_ex
                        # exception of ihc.find('div') being non existant

            # Recreates cell indexes
            for i in [-numberOfRowsAdded...renderedRows]
                $('.mtgR'+id+'_r'+i).each (index) ->
                    $(this).attr('id', 'mtgC' + id + '_c' + index + 'r' + i)
                    $(this).attr('class', 'my-tablegrid-cell mtgC' + id + ' mtgC' + id + '_c' + index + ' mtgR' + id + '_r' + i)

                $('.mtgIR'+id+'_r'+i).each (index, div) ->
                    $(div).attr('id', 'mtgIC' + id + '_c' + index + 'r' + i)
                    modifiedCellClass = if $(div).attr('class').match(/modified-cell/) then ' modified-cell' else ''
                    $(div).attr('class', 'my-tablegrid-inner-cell mtgIC' + id + ' mtgIC' + id + '_c' + index + ' mtgIR' + id + '_r' + i + modifiedCellClass)
                    if $(div).first() and $(div).first().is(':input')  # when it contains a checkbox or radio button
                        input = $(div).first()
                        input.attr('id', 'mtgInput' + id + '_c' + index + 'r' + i)
                        input.attr('name', 'mtgInput' + id + '_c' + index + 'r' + i)
                        input.attr('class', 'mtgInput' + id + '_c' + index)

            @sortedColumnIndex = toColumnId if fromColumnId == @sortedColumnIndex


        ###
        # Add Key behavior functionality to the table grid
        ###
        _addKeyBehavior : ->
            rows = @rows
            renderedRows = @renderedRows
            renderedRowsAllowed = @renderedRowsAllowed
            beginAtRow = renderedRows - renderedRowsAllowed
            beginAtRow = 0 if beginAtRow < 0
            @_addKeyBehaviorToRow(rows[j], j) for j in [beginAtRow...renderedRows]

        ###
        # Add key behavior to row.
        ###
        _addKeyBehaviorToRow : (row, j) ->
            id = @_mtgId
            cm = @columnModel
            keys = @keys
          
            for i in [0...cm.length]
                element = $('#mtgC' + id + '_c' + i + 'r' + j)
                do (element, i, j) =>
                    if cm[i].editable
                        keys.events.remove.action(element)
                        keys.events.remove.esc(element)
                        keys.events.remove.blur(element)

                        f_action = =>
                            if @editedCellId == null or @editedCellId != element.attr('id')
                                @editedCellId = element.attr('id')
                                @_editCellElement(element)
                            else
                                @editedCellId = null if @_blurCellElement(element)

                        keys.events.action(element, f_action)

                        f_esc = (element) => @editedCellId = null if @_blurCellElement(element)
                        keys.events.esc(element, f_esc)

                        f_blur = =>
                            @editedCellId = null if @_blurCellElement(element)
                            @options.onCellBlur(element, row[i], i, j, cm[i].id) if @options.onCellBlur?

                        keys.events.blur(element, f_blur)

                    keys.events.remove.focus(element)
                    f_focus = =>
                        @options.onCellFocus(element, row[i], i, j, cm[i].id) if @options.onCellFocus?
                    keys.events.focus(element, f_focus)

        ###
        # When a cell is edited
        ###
        _editCellElement : (element) ->
            @keys._bInputFocused = true
            cm = @columnModel
            coords = @getCurrentPosition()
            x = coords[0]
            y = coords[1]
            width = element.width()
            height = element.height()
            innerElement = element.find('div')
            value = @getValueAt(x, y)
            editor = @columnModel[x].editor or 'input'
            input = null
            isInputFlg = !(editor == 'radio' or editor == 'checkbox' or editor instanceof TableGrid.CellCheckbox or editor instanceof TableGrid.CellRadioButton)
          
            if isInputFlg
                element.css('height', @options.cellHeight + 'px')
                innerElement.css({
                    'position': 'relative',
                    'width': width + 'px',
                    'height': height + 'px',
                    'padding': '0',
                    'border': '0',
                    'margin': '0'
                })
                innerElement.html('')
                value = cm[x].renderer(value, editor.getItems(), @getRow(y)) if editor instanceof Autocompleter # when is a list
                # Creating a normal input
                inputId = 'mtgInput' + @_mtgId + '_c' + x + 'r' + y
                input = $('<input>').attr({'id' : inputId, 'type' : 'text', 'value' : value})
                input.addClass('my-tablegrid-textfield')
                input.css({
                    'padding' : '3px',
                    'width' : width + 'px'
                })
                innerElement.append(input)
                editor.setTableGrid(this)
                editor.render(input, true)
                editor.validate() if editor.validate
                input.focus()
                input.select()
            else if editor == 'checkbox' or editor instanceof TableGrid.CellCheckbox
                input = $('#mtgInput' + @_mtgId + '_c' + x + 'r' + y)
                input.attr('checked', !input.is(':checked'))
                if editor.selectable == undefined or !editor.selectable
                    value = input.is(':checked')
                    value = editor.getValueOf(input.is(':checked')) if editor.hasOwnProperty('getValueOf')
                    @setValueAt(value, x, y, false)
                    @modifiedRows.push(y) if y >= 0 and @modifiedRows.indexOf(y) == -1 # if doesn't exist in the array the row is registered

                editor.onClickCallback(value, input.is(':checked')) if editor instanceof TableGrid.CellCheckbox and editor.onClickCallback
                @keys._bInputFocused = false
                @editedCellId = null
                innerElement.addClass('modified-cell') if y >= 0 and (editor.selectable == undefined or !editor.selectable)
            else if editor == 'radio' or editor instanceof TableGrid.CellRadioButton
                input = $('#mtgInput' + @_mtgId + '_c' + x + 'r' + y)
                input.attr('checked', !input.is(':checked'))
                value = input.is(':checked')
                value = editor.getValueOf(input.is(':checked')) if editor.hasOwnProperty('getValueOf')
                @setValueAt(value, x, y, false)
                @modifiedRows.push(y) if y >= 0 and @modifiedRows.indexOf(y) == -1 #if doesn't exist in the array the row is registered
                editor.onClickCallback(value, input.is(':checked')) if editor instanceof TableGrid.CellRadioButton and editor.onClickCallback
                @keys._bInputFocused = false
                @editedCellId = null
                innerElement.addClass('modified-cell') if y >= 0 and (editor.selectable == undefined or !editor.selectable)
            # end if

        ###
        # When the cell is blured
        ###
        _blurCellElement : (element) ->
            return unless @keys._bInputFocused
            console.log '_blurCellElement is called ' + element?
            return unless element?
            console.log 'element exist n  ow :-) ' + element.length + ' id: ' + element.attr('id')
            id = @_mtgId
            keys = @keys
            cm = @columnModel
            width = element.width()
            height = element.height()
            coords = @getCurrentPosition()
            x = coords[0]
            y = coords[1]
            cellHeight = @cellHeight
            innerId = '#mtgIC' + id + '_c' + x + 'r' + y
            input = $('#mtgInput' + id + '_c' + x + 'r' + y)
            innerElement = $(innerId)
            value = input.val()
            editor = cm[x].editor or 'input'
            type = cm[x].type or 'string'
            columnId = cm[x].id
            alignment = if type == 'number' then 'right' else 'left'
          
            isInputFlg = !(editor == 'radio' or editor == 'checkbox' or editor instanceof TableGrid.CellCheckbox or editor instanceof TableGrid.CellRadioButton)
            if isInputFlg
                editor.hide() if editor.hide? # this only happen when editor is a Combobox
                return false if editor instanceof DatePicker and editor.visibleFlg
                editor.reset() if editor.reset?
                element.css('height', cellHeight + 'px')
                innerElement.css({
                    'width' : (width - 6) + 'px',
                    'height' : (height - 6) + 'px',
                    'padding' : '3px',
                    'text-align' : alignment
                }).html(value)

            # I hope I can find a better solution
            value = editor.getSelectedValue(value) if editor instanceof Autocompleter
            console.log 'value : ' + value
            if y >= 0 and y < @rows.length and @rows[y][columnId] != value
                @rows[y][columnId] = value
                innerElement.addClass('modified-cell')
                @modifiedRows.push(y) if @modifiedRows.indexOf(y) == -1 # if doesn't exist in the array the row is registered
            else if y < 0
                @newRowsAdded[Math.abs(y) - 1][columnId] = value
            else if y >= @rows.length
                @newRowsAdded[Math.abs(y) - @rows.length][columnId] = value
            #end if
            editor.afterUpdateCallback(element, value) if (editor instanceof BrowseInput or editor instanceof TextField or editor instanceof DatePicker) and editor.afterUpdateCallback?
            keys._bInputFocused = false
            return true

        ###
        # Applies header buttons
        ###
        _applyHeaderButtons : ->
            id = @_mtgId
            cm = @columnModel
            headerHeight = @headerHeight
            headerButton = $('#mtgHB' + id)
            headerButtonMenu = $('#mtgHBM' + id)
            sortAscMenuItem = $('#mtgSortAsc'+id)
            sortDescMenuItem = $('#mtgSortDesc'+id)
            selectedHCIndex = -1
            for element in $('.mtgIHC' + id)
                do (element) =>
                    topPos = 0 # topPos is here because ouside mess with the other topPos var
                    topPos += @titleHeight if @options.title?
                    topPos += @toolbarHeight if @options.toolbar?
                    editor = null
                    sortable = true
                    hbHeight = null
                    $(element).on 'mousemove', =>
                        return unless $(element).attr('id')
                        elementId = $(element).attr('id')
                        selectedHCIndex = elementId.match(/_c(\d*)/)[1] # extract column number from id
                        editor = cm[selectedHCIndex].editor
                        sortable = cm[selectedHCIndex].sortable
                        hbHeight = cm[selectedHCIndex].height
                        if sortable or editor == 'checkbox' or editor instanceof TableGrid.CellCheckbox
                            hc = $(element).closest('th') # header column
                            leftPos = hc.position().left + hc.outerWidth()
                            leftPos = leftPos - 16 - @scrollLeft
                            if leftPos < @bodyDiv[0].clientWidth
                                headerButton.css({
                                    'top' : (topPos + 3 + headerHeight - hbHeight) + 'px',
                                    'left' : leftPos + 'px',
                                    'height' : hbHeight + 'px',
                                    'visibility' : 'visible'
                                })

                            sortAscMenuItem.on 'click', => @_sortData(selectedHCIndex, 'ASC')
                            sortDescMenuItem.on 'click', => @_sortData(selectedHCIndex, 'DESC')

                    # Sorting when click on header column
                    $(element).on 'click', =>
                        return unless $(element).attr('id')
                        elementId = $(element).attr('id')
                        selectedHCIndex = elementId.match(/_c(\d*)/)[1] # extract column number from id
                        @_toggleSortData(selectedHCIndex)


            headerButton.on 'click', =>
                cm = @columnModel
                if headerButtonMenu.css('visibility') == 'hidden'
                    if cm[selectedHCIndex].sortable
                        $('#mtgSortDesc' + id).show()
                        $('#mtgSortAsc' + id).show()
                    else
                        $('#mtgSortDesc' + id).hide()
                        $('#mtgSortAsc' + id).hide()

                    selectAllItem = $('#mtgHBM' + id + ' .mtgSelectAll:first')
                    if @renderedRows > 0 and (cm[selectedHCIndex].editor == 'checkbox' or cm[selectedHCIndex].editor instanceof TableGrid.CellCheckbox)
                        selectAllItem.find('input').attr('checked', cm[selectedHCIndex].selectAllFlg)
                        selectAllItem.show()
                        selectAllItem.on 'click', => # onclick handler
                            flag = cm[selectedHCIndex].selectAllFlg = $('#mtgSelectAll' + id).is(':checked')
                            selectableFlg = false
                            selectableFlg = true if cm[selectedHCIndex].editor instanceof TableGrid.CellCheckbox and cm[selectedHCIndex].editor.selectable
                            renderedRows = @renderedRows
                            beginAtRow = 0
                            beginAtRow = -@newRowsAdded.length if @newRowsAdded.length > 0
                            x = selectedHCIndex
                            for y in [beginAtRow...renderedRows]
                                element = $('#mtgInput' + id + '_c' + x + 'r' + y)
                                element.attr('checked', flag)
                                value = flag
                                if !selectableFlg
                                    value = cm[x].editor.getValueOf(element.is(':checked')) if cm[x].editor.hasOwnProperty('getValueOf')
                                    @setValueAt(value, x, y, false)
                                    # if doesn't exist in the array the row is registered
                                    @modifiedRows.push(y) if y >= 0 and @modifiedRows.indexOf(y) == -1
                    else
                        selectAllItem.hide()

                    leftPos = parseInt(headerButton.css('left'))
                    topPos = @headerHeight + 2
                    topPos += @titleHeight if @options.title?
                    topPos += @toolbarHeight if @options.toolbar?
                    headerButtonMenu.css({
                        'top' : topPos + 'px',
                        'left' : leftPos + 'px',
                        'visibility' : 'visible'
                    })
                else
                    headerButtonMenu.css('visibility', 'hidden')

            miFlg = false
            headerButtonMenu.on 'mouseenter', -> miFlg = true

            headerButtonMenu.on 'mouseleave', (event) ->
                miFlg = false
                setTimeout(( ->
                    headerButtonMenu.css('visibility', 'hidden') unless miFlg
                ), 500)

        ###
        # Sort data displayed in TableGrid.
        ###
        _sortData : (idx, ascDescFlg) ->
            cm = @columnModel
            id = @_mtgId
            if cm[idx].sortable
                $('#mtgSortIcon'+id+'_c'+idx).attr('class', if (ascDescFlg == 'ASC') then 'my-tablegrid-sort-asc-icon' else 'my-tablegrid-sort-desc-icon')
                @request[@options.sortColumnParameter] = cm[idx].id;
                @request[@options.ascDescFlagParameter] = ascDescFlg;
                @_retrieveDataFromUrl(1)
                $('#mtgSortIcon'+id+'_c'+@sortedColumnIndex).css('visibility', 'hidden')
                $('#mtgIHC'+id+'_c'+@sortedColumnIndex).css('color', 'dimgray')
                $('#mtgSortIcon'+id+'_c'+idx).css('visibility', 'visible')
                $('#mtgIHC'+id+'_c'+idx).css('color', 'black')
                @sortedColumnIndex = idx
                cm[idx].sortedAscDescFlg = ascDescFlg

        ###
        # Toggle sorting between descendant and ascendant options.
        ###
        _toggleSortData : (idx) ->
            cm = @columnModel
            if cm[idx].sortedAscDescFlg == 'DESC'
                @_sortData(idx, 'ASC')
            else
                @_sortData(idx, 'DESC')

        ###
        # Toggle column visibility.
        # @param columnId column id
        ###
        _toggleColumnVisibility : (columnId) ->
            console.log 'toggleColumnVisibility: ' + columnId
            id = @_mtgId
            cm = @columnModel
            @_blurCellElement(@keys._nCurrentFocus) # in case there is a cell in editing mode
            @keys.blur() #remove the focus of the selected cell
            headerRowTable = $('#mtgHRT' + id)
            bodyTable = $('#mtgBT' + id)
            index = -1
            index = i for i in [0...cm.length] when cm[i].id == columnId
            console.log 'hiding index : ' + index
            targetColumn = $('#mtgHC' + id + '_c' + index)
            $('#mtgHB' + id).css('visibility', 'hidden')
            width = 0

            if cm[index].visible  # hide
                width = targetColumn.width()
                targetColumn.hide()
                $('.mtgC'+id+ '_c'+index).hide()
                cm[index].visible = false
                @headerWidth = @headerWidth - width
            else # show
                targetColumn.show()
                width = targetColumn.width() + 2
                $('.mtgC'+id+ '_c'+index).show()
                cm[index].visible = true
                @headerWidth = @headerWidth + width

            headerRowTable.attr('width', @headerWidth + 21)
            headerRowTable.css('width', (@headerWidth + 21) + 'px')
            bodyTable.attr('width', @headerWidth)
            bodyTable.css('width', @headerWidth + 'px')

        ###
        # Calculates full padding.
        ###
        _fullPadding : (element, s) ->
            padding = parseInt(element.css('padding-'+s))
            padding = if isNaN(padding) then 0 else padding
            border = parseInt(element.css('border-'+s+'-width'))
            border = if isNaN(border) then 0 else border
            return padding + border

        ###
        # Retrieves data from url using an AJAX call, expected result must
        # in JSON format otherwise it will call onFailure callback.
        ###
        _retrieveDataFromUrl : (pageNumber, firstTimeFlg) ->
            if !firstTimeFlg and @options.onPageChange?
                return unless @options.onPageChange()
            pageParameter = 'page'
            pageParameter = @pager.pageParameter if @pager != null and @pager.pageParameter
            @request[pageParameter] = pageNumber
            @_toggleLoadingOverlay()
            column.selectAllFlg = false for column in @columnModel
            $.ajax({
                url : @url,
                data : @request,
                context : @, # TODO here it maybe will be a problem
                dataType : 'json',
                complete : (response) ->
                    tableModel = $.parseJSON(response.responseText)
                    try
                        @rows = tableModel.rows or []
                        @pager = null
                        @pager = tableModel.options.pager if tableModel.options? and tableModel.options.pager?
                        @pager = {} unless @pager?
                        @pager.pageParameter = pageParameter
                        @renderedRows = 0
                        @innerBodyDiv.html(@_createTableBody(tableModel.rows))
                        @bodyTable = $('#mtgBT' + @_mtgId)
                        if tableModel.rows.length > 0 and !firstTimeFlg
                            @_applyCellCallbacks()
                            @keys = new KeyTable(@) # TODO not sure if this work
                            @_addKeyBehavior()

                        if @pager?
                            @pagerDiv.html(@_updatePagerInfo()) # update pager info panel
                            @_addPagerBehavior()

                        @options.afterRender() if @options.afterRender?
                    catch ex
                        @options.onFailure(response) if @options.onFailure?
                    finally
                        @_toggleLoadingOverlay()
                        @bodyDiv.scrollTop(@scrollTop = 0)
                        @bodyDiv.trigger('dom:dataLoaded') if firstTimeFlg
                fail : (response) ->
                    @options.onFailure(response) if @options.onFailure?
                    @_toggleLoadingOverlay()
                    @bodyDiv.scrollTop(@scrollTop = 0)
                    @bodyDiv.trigger('dom:dataLoaded') if firstTimeFlg
            })

        ###
        # Updates pager info.
        ###
        _updatePagerInfo : (emptyFlg) ->
            id = @_mtgId
            return '<span id="mtgLoader'+id+'" class="mtgLoader">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>' if emptyFlg
            html = []
            idx = 0
            pager = @pager
            if @pager.total > 0
                temp = i18n.getMessage('message.totalDisplay', {'total' : pager.total})
                temp += i18n.getMessage('message.rowsDisplay', {'from' : pager.from, 'to' : pager.to}) if pager.from and pager.to
                html[idx++] = '<span class="my-tablegrid-pager-message">'+temp+'</span>'
                if pager.pages?
                    input = '<input type="text" name="mtgPageInput'+id+'" id="mtgPageInput'+id+'" value="'+pager.currentPage+'" class="my-tablegrid-page-input" size="3" maxlength="3">'
                    temp = i18n.getMessage('message.pagePrompt', {'pages' : pager.pages, 'input' : input})
                    html[idx++] = '<table class="my-tablegrid-pager-table" border="0" cellpadding="0" cellspacing="0">'
                    html[idx++] = '<tbody>'
                    html[idx++] = '<tr>'
                    html[idx++] = '<td><div id="mtgLoader'+id+'" class="mtgLoader">&nbsp;</div></td>'
                    html[idx++] = '<td><div class="my-tablegrid-pager-separator">&nbsp;</div></td>'
                    html[idx++] = '<td><a id="mtgFirst'+id+'" class="my-tablegrid-pager-control"><div class="first-page">&nbsp;</div></a></td>'
                    html[idx++] = '<td><a id="mtgPrev'+id+'" class="my-tablegrid-pager-control"><div class="previous-page">&nbsp;</div></a></td>'
                    html[idx++] = '<td><div class="my-tablegrid-pager-separator">&nbsp;</div></td>'
                    html[idx++] = temp
                    html[idx++] = '<td><div class="my-tablegrid-pager-separator">&nbsp;</div></td>'
                    html[idx++] = '<td><a id="mtgNext'+id+'" class="my-tablegrid-pager-control"><div class="next-page">&nbsp;</div></a></td>'
                    html[idx++] = '<td><a id="mtgLast'+id+'" class="my-tablegrid-pager-control"><div class="last-page">&nbsp;</div></a></td>'
                    html[idx++] = '</tr>'
                    html[idx++] = '</tbody>'
                    html[idx++] = '</table>'
                else
                    html[idx++] = '<table class="my-tablegrid-pager-table" border="0" cellpadding="0" cellspacing="0">'
                    html[idx++] = '<tbody>'
                    html[idx++] = '<tr>'
                    html[idx++] = '<td><div id="my-tablegrid-pager-loader'+id+'" class="mtgLoader">&nbsp;</div></td>'
                    html[idx++] = '</tr>'
                    html[idx++] = '</tbody>'
                    html[idx++] = '</table>'
            else
                html[idx++] = '<span class="my-tablegrid-pager-message">'+i18n.getMessage('message.noRecordFound')+'</span>'

            return html.join('')

        ###
        # Add pager behavior.
        ###
        _addPagerBehavior : ->
            id = @_mtgId
            return unless @pager.pages
            currentPage = @pager.currentPage
            pages = @pager.pages
            total = @pager.total
            if total > 0
                if currentPage > 1
                    $('#mtgFirst'+id).find('div').attr('class', 'first-page')
                    $('#mtgFirst'+id).on 'click', => @_retrieveDataFromUrl(1)
                else
                    $('#mtgFirst'+id).find('div').attr('class', 'first-page-disabled')

                if currentPage > 0 and currentPage < pages
                    $('#mtgNext'+id).find('div').attr('class', 'next-page')
                    $('#mtgNext'+id).on 'click', => @_retrieveDataFromUrl(parseInt(currentPage) + 1)
                else
                    $('#mtgNext'+id).find('div').attr('class', 'next-page-disabled')

                if currentPage > 1 and currentPage <= pages
                    $('#mtgPrev'+id).find('div').attr('class', 'previous-page')
                    $('#mtgPrev'+id).on 'click', => @_retrieveDataFromUrl(parseInt(currentPage) - 1)
                else
                    $('#mtgPrev'+id).find('div').attr('class', 'previous-page-disabled')

                if currentPage < pages
                    $('#mtgLast'+id).find('div').attr('class', 'last-page')
                    $('#mtgLast'+id).on 'click', => @_retrieveDataFromUrl(@pager.pages)
                else
                    $('#mtgLast'+id).find('div').attr('class', 'last-page-disabled')

                $('#mtgPageInput'+id).on 'keydown', (event) =>
                    if event.which == eventUtil.KEY_RETURN
                        pageNumber = $('#mtgPageInput'+id).val()
                        pageNumber = pages if pageNumber > pages
                        pageNumber = '1' if pageNumber < 1
                        $('#mtgPageInput'+id).val(pageNumber)
                        @_retrieveDataFromUrl(pageNumber)
        ###
        # Resize handler.
        ###
        resize : ->
            target = $(@target)
            width = @options.width or (target.width() - @_fullPadding(target, 'left') - @_fullPadding(target, 'right')) + 'px'
            height = @options.height or (target.height() - @_fullPadding(target, 'top') - @_fullPadding(target, 'bottom')) + 'px'
            @tableWidth = parseInt(width) - 2
            tallerFlg = false
            tallerFlg = true if (parseInt(height) - 2) > @tableHeight
            @tableHeight = parseInt(height) - 2

            headerButton = $('#mtgHB' + @_mtgId)
            headerButton.css('visibility', 'hidden') if headerButton

            @tableDiv.css({
                'width' : @tableWidth + 'px',
                'height' : @tableHeight + 'px'
            })

            @headerTitle.css('width', (@tableWidth - 6) + 'px') if @headerTitle
            @headerToolbar.css('width', (@tableWidth - 4) + 'px') if @headerToolbar
            @headerRowDiv.css('width', @tableWidth + 'px')
            @overlayDiv.css('width', (@tableWidth + 2) + 'px')
            settingButton = $('#mtgSB' + @_mtgId)
            settingButton.css('left', (@tableWidth - 20) + 'px') if settingButton
            @bodyHeight = @tableHeight - @headerHeight - 3
            @bodyHeight = @bodyHeight - @titleHeight - 1 if @options.title
            @overlayDiv.css('height', (@bodyHeight + 4) + 'px')
            @bodyHeight = @bodyHeight - @pagerHeight if @options.pager
            @bodyHeight = @bodyHeight - @pagerHeight if @options.toolbar
            @bodyDiv.css({
                'width' : @tableWidth + 'px',
                'height' : @bodyHeight + 'px'
            })

            if @options.pager
                topPos = @bodyHeight + @headerHeight +  5
                topPos += @titleHeight if @options.title
                topPos += @toolbarHeight if @options.toolbar
                @pagerDiv.css({
                    'top' : topPos + 'px',
                    'width' : (@tableWidth - 4) + 'px'
                })

            @renderedRowsAllowed = Math.floor(@bodyDiv[0].clientHeight / @options.cellHeight)
            if tallerFlg
                html = @_createTableBody(@rows);
                @bodyTable.find('tbody').append(html)
                @_addKeyBehavior()
                @_applyCellCallbacks()

        ###
        # Returns value at given coordinates.
        ###
        getValueAt : (x, y) ->
            value = null
            columnId = @columnModel[x].id
            rows = @rows
            newRowsAdded = @newRowsAdded
            if y >= 0 and y < rows.length
                value = @rows[y][columnId]
            else if y < 0
                value = newRowsAdded[Math.abs(y)-1][columnId]
            else if y >= rows.length
                value = newRowsAdded[Math.abs(y) - rows.length][columnId]
            return value

        ###
        # Set value at given coordinates, refreshValueFlg makes the
        # change either visible or not.
        ###
        setValueAt : (value, x, y, refreshValueFlg) ->
            cm = @columnModel
            id = @_mtgId
            editor = cm[x].editor
            columnId = cm[x].id
            rows = @rows
            newRowsAdded = @newRowsAdded

            if refreshValueFlg == undefined or refreshValueFlg
                if editor != null and (editor == 'checkbox' or editor instanceof TableGrid.CellCheckbox or editor == 'radio' or editor instanceof TableGrid.CellRadioButton)
                    input = $('#mtgInput'+id+'_c'+x+'r'+y)
                    if editor.hasOwnProperty('getValueOf')
                        trueVal = editor.getValueOf(true)
                        if value == trueVal
                            input.attr('checked', true)
                        else
                            input.attr('checked', false)
                            value = editor.getValueOf(false)
                    else
                        if (eval(value))
                            input.attr('checked', true)
                        else
                            input.attr('checked', false)
                            value = false
                else
                    $('#mtgIC'+id+'_c'+x+'r'+y).html(value)

            if y >= 0 and y < rows.length
                rows[y][columnId] = value
            else if y  < 0
                newRowsAdded[Math.abs(y) - 1][columnId] = value
            else if y >= rows.length
                newRowsAdded[Math.abs(y) - rows.length][columnId] = value
        ###
        # Returns column index.
        ###
        getColumnIndex : (id) ->
            index = -1
            for i in [0...@columnModel.length]
                if @columnModel[i].id == id
                    index = @columnModel[i].positionIndex
                    break
            return index;

        ###
        # Returns index of a given id column model item.
        ###
        getIndexOf : (id) ->
            idx = -1
            for column in @columnModel
                if column.id == id
                    idx = i
                    break
            return idx

        ###
        # Returns current position.
        ###
        getCurrentPosition : ->
            return [@keys._xCurrentPos, @keys._yCurrentPos]

        ###
        # Returns cell element at given position.
        ###
        getCellElementAt : (x, y) ->
            return $('#mtgC'+@_mtgId + '_c' + x + 'r' + y)

        ###
        # Returns modified rows.
        ###
        getModifiedRows : ->
            result = []
            modifiedRows = @modifiedRows
            rows = @rows
            for i in [0...modifiedRows.length]
                idx = modifiedRows[i]
                result.push(rows[idx])
            return result

        ###
        # Returns new rows added.
        ###
        getNewRowsAdded : ->
            return @newRowsAdded

        ###
        # Returns deleted rows.
        ###
        getDeletedRows : ->
            return @deletedRows

        ###
        # Returns the selected rows by column
        #
        # @param id of the selectable column
        ###
        getSelectedRowsByColumn : (id) ->
            idx = @getIndexOf(id)
            result = []
            rows = @rows
            newRowsAdded = @newRowsAdded
            return null if idx < 0
            selectedRowsIdx = @_getSelectedRowsIdx(idx)
            for i in [0...selectedRowsIdx.length]
                rowIdx = selectedRowsIdx[i]
                if rowIdx >= 0 and rowIdx < rows.length
                    result.push(rows[rowIdx])
                else if rowIdx < 0
                    result.push(newRowsAdded[Math.abs(rowIdx) - 1])
                else if rowIdx >= rows.length
                    result.push(newRowsAdded[Math.abs(rowIdx) - rows.length])
            return result;

        ###
        # Returns an array containing the correlative
        # index of the selected rows.
        ###
        _getSelectedRowsIdx: (idx) ->
            result = []
            id = @_mtgId
            cm = @columnModel
            newRowsAdded = @newRowsAdded
            renderedRows = @renderedRows
            addNewRowsToEndBehaviorFlg = @options.addNewRowsToEndBehaviour

            idx = idx or -1 # Selectable column index
            selectAllFlg = false
            if idx == -1
                for column in cm
                    if column.editor == 'checkbox' or column.editor instanceof TableGrid.CellCheckbox and column.editor.selectable
                        idx = column.positionIndex
                        selectAllFlg = column.selectAllFlg
                        break
            else
                selectAllFlg = cm[idx].selectAllFlg

            if idx >= 0
                j = 0
                y = 0
                if newRowsAdded.length > 0 # there are new rows added
                    if !addNewRowsToEndBehaviorFlg
                        for j in [0...newRowsAdded.length]
                            y = -(j + 1)
                            result.push(y) if $('#mtgInput'+id+'_c'+idx+'r'+y).is(':checked')
                    else
                        for j in [0...newRowsAdded.length]
                            y = j + renderedRows
                            result.push(y) if $('#mtgInput'+id+'_c'+idx+'r'+y).is(':checked')

                for j in [0...renderedRows]
                    y = j
                    result.push(y) if @deletedRows.indexOf(@getRow(y)) == -1 and $('#mtgInput'+id+'_c'+idx+'r'+y).size() > 0 and $('#mtgInput'+id+'_c'+idx+'r'+y).is(':checked')


                if selectAllFlg and renderedRows < @rows.length
                    result.push(j) for j in [renderedRows...@rows.length]

            return result

        ###
        # Highlight given row id.
        ###
        highlightRow : (id, value) ->
            $('.mtgRow'+@_mtgId).removeClass('focus')
            index = @getColumnIndex(id)
            rowIndex = -1
            for i in [0...@rows.length]
                if @rows[i][index] == value
                    rowIndex = i
                    break
            $('#mtgRow'+@_mtgId+'_r'+rowIndex).addClass('focus') if rowIndex >= 0

        ###
        # Returns row for given "y" position.
        ###
        getRow : (y) ->
            result = null
            result = if y >= 0 then @rows[y] else @newRowsAdded[-(y + 1)]
            return result

        ###
        # Returns column values as an array.
        ###
        getColumnValues : (id) ->
            result = []
            j = 0
            i = 0
            result[j++] = @newRowsAdded[i][id] for i in [0...@newRowsAdded.length]
            result[j++] = @rows[i][id] for i in [0...@rows.length]
            return result

        ###
        # Clears internal table grid status.
        ###
        clear : ->
            @modifiedRows = []
            @deletedRows = []
            @newRowsAdded = []

        ###
        # Add a new row.
        ###
        addNewRow : (newRow) ->
            keys = @keys
            bodyTable = @bodyTable
            cm = @columnModel
            index = @newRowsAdded.length
            renderedRows = @renderedRows

            if newRow == undefined
                newRow = {}
                newRow[cm[j].id] = '' for j in [0...cm.length]

            @newRowsAdded.push(newRow)
            if !@options.addNewRowsToEndBehaviour
                index = -(index + 1)
                bodyTable.find('tbody').prepend(@_createRow(newRow, index))
                keys.setTopLimit(-index)
                @bodyDiv.scrollTop(@scrollTop = 0)
            else
                index = renderedRows + index
                bodyTable.find('tbody').append(@_createRow(newRow, index))
                numberOfRows = renderedRows + @newRowsAdded.length
                @keys.setNumberOfRows(numberOfRows)
                @_scrollToRow(numberOfRows)

            @_addKeyBehaviorToRow(newRow, index)
            @_applyCellCallbackToRow(-index)


        ###
        # Deletes selected rows.
        ###
        deleteRows : ->
            id = @_mtgId
            selectedRows = @_getSelectedRowsIdx()
            i = 0
            y = 0
            for i in [0...selectedRows.length]
                y = selectedRows[i]
                if y >= 0 and y < @rows.length
                    @deletedRows.push(@getRow(y))
                else if y < 0
                    @newRowsAdded[Math.abs(y) - 1] = null
                else if y >= @rows.length
                    @newRowsAdded[Math.abs(y) - @rows.length] = null
                $('#mtgRow'+id+'_r'+y).hide()

            # compacting array
            temp = []
            temp.push(index) for index in @newRowsAdded when index != null
            @newRowsAdded = temp

            totalDiv = $('#mtgTotal')
            if totalDiv?
                total = parseInt(totalDiv.html())
                total -= selectedRows.length
                totalDiv.html(total)

            toDiv = $('#mtgTo')
            if toDiv?
                to = parseInt(toDiv.html())
                to -= selectedRows.length
                toDiv.html(to)
            @_syncScroll()

        ###
        # Refresh data displayed in TableGrid.
        ###
        refresh : ->
            @modifiedRows = []
            @deletedRows = []
            @newRowsAdded = []
            @_retrieveDataFromUrl(1, false)

        ###
        # Empty data displayed in TableGrid.
        ###
        empty : ->
            bodyTable = @bodyTable
            bodyTable.find('tbody').html('')
            @rows = []
            @pager.total = 0
            @pagerDiv.html(@_updatePagerInfo())

        ###
        # Turns an array row into an object row
        ###
        _fromArrayToObject : (row) ->
            result = null
            cm = @columnModel
            if row instanceof Array
                result = {}
                for i in [0...cm.length]
                    result[cm[i].id] = row[cm[i].positionIndex]
            else if row instanceof Object
                result = row
            return result
    #end TableGrid

    TableGrid::ADD_BTN = 1
    TableGrid::DEL_BTN = 4
    TableGrid::SAVE_BTN = 8

    class TableGrid.CellCheckbox
        constructor : (options) ->
            options = options or {}
            @onClickCallback = options.onClick or null
            @selectable = options.selectable or false
            @getValueOf = options.getValueOf if options.getValueOf?

    class TableGrid.CellRadioButton
        constructor : (options) ->
            options = options or {}
            @onClickCallback = options.onClick or null
            @selectable = options.selectable or false
            @getValueOf = options.getValueOf if options.getValueOf?

    class HeaderBuilder
        constructor: (id, cm) ->
            @columnModel = cm
            @_mtgId = id
            @filledPositions = []
            @_leafElements = []
            @defaultHeaderColumnWidth = 100
            @cellHeight = 24
            @rnl = @getHeaderRowNestedLevel()
            @_validateHeaderColumns()
            @headerWidth = @getTableHeaderWidth()
            @headerHeight = @getTableHeaderHeight()

        ###
        # Creates header row
        ###
        _createHeaderRow : ->
            thTmpl = '<th id="mtgHC{id}_c{x}" colspan="{colspan}" rowspan="{rowspan}" width="{width}" height="{height}" style="position:relative;width:{width}px;height:{height}px;padding:0;margin:0;border-bottom-color:{color};display:{display}" class="my-tablegrid-header-cell mtgHC{id}">'
            thTmplLast = '<th id="mtgHC{id}_c{x}" colspan="{colspan}" rowspan="{rowspan}" width="{width}" height="{height}" style="width:{width}px;height:{height}px;padding:0;margin:0;border-right:none;border-bottom:1px solid #ccc;" class="my-tablegrid-header-cell mtgHC{id}">'
            ihcTmpl = '<div id="mtgIHC{id}_c{x}" class="my-tablegrid-inner-header-cell mtgIHC{id}" style="float:left;width:{width}px;height:{height}px;padding:4px 3px;z-index:20">'
            ihcTmplLast = '<div class="my-tablegrid-inner-header-cell" style="position:relative;width:{width}px;height:{height}px;padding:3px;z-index:20">'
            hsTmpl = '<div id="mtgHS{id}_c{x}" class="mtgHS mtgHS{id}" style="float:right;width:1px;height:{height}px;z-index:30">'
            siTmpl = '<span id="mtgSortIcon{id}_c{x}" style="width:8px;height:4px;visibility:hidden">&nbsp;&nbsp;&nbsp;</span>'
            cm = @columnModel
            id = @_mtgId
            rnl = @rnl #row nested level

            html = []
            idx = 0
            @filledPositions = []

            html[idx++] = '<table id="mtgHRT'+id+'" width="'+(@headerWidth+21)+'" cellpadding="0" cellspacing="0" border="0" class="my-tablegrid-header-row-table">'
            html[idx++] = '<thead>'

            temp = null
            for i in [0...rnl] # for each nested level
                row = @_getHeaderRow(i)
                html[idx++] = '<tr>'
                x = @_getStartingPosition()
                for j in [0...row.length]
                    cell = row[j]
                    colspan = 1
                    rowspan = 1
                    cnl = @_getHeaderColumnNestedLevel(cell)
                    display = ''
                    if cnl == 0 # is a leaf element
                        rowspan = rnl - i
                        cell.height = rowspan * (@cellHeight + 2)
                        x = @_getNextIndexPosition(x)
                        display = if !cell.visible then 'none' else ''
                        temp = thTmpl.replace(/\{id\}/g, id)
                        temp = temp.replace(/\{x\}/g, x)
                        temp = temp.replace(/\{colspan\}/g, colspan)
                        temp = temp.replace(/\{rowspan\}/g, rowspan)
                        temp = temp.replace(/\{color\}/g, '#ccc')
                        temp = temp.replace(/\{display\}/g, display)

                        cellWidth = cell.width or '80'
                        cellWidth = parseInt(cellWidth)
                        temp = temp.replace(/\{width\}/g, cellWidth)
                        temp = temp.replace(/\{height\}/g, cell.height)
                        html[idx++] = temp

                        temp = ihcTmpl.replace(/\{id\}/g, id)
                        temp = temp.replace(/\{x\}/g, x)
                        temp = temp.replace(/\{width\}/g,  cellWidth - 8)
                        temp = temp.replace(/\{height\}/g, cell.height - 6)
                        html[idx++] = temp
                        html[idx++] = row[j].title
                        html[idx++] = '&nbsp;'
                        temp = siTmpl.replace(/\{id\}/g, id)
                        temp = temp.replace(/\{x\}/g, x)
                        html[idx++] = temp
                        html[idx++] = '</div>'

                        temp = hsTmpl.replace(/\{id\}/g, id)
                        temp = temp.replace(/\{x\}/g, x)
                        temp = temp.replace(/\{height\}/g, cell.height)
                        html[idx++] = temp
                        html[idx++] = '&nbsp;'
                        html[idx++] = '</div>'
                        html[idx++] = '</th>'
                        @filledPositions.push(x)
                        @_leafElements[x] = cell
                    else
                        colspan = @_getNumberOfNestedCells(cell)
                        x += colspan - 1
                        temp = thTmpl.replace(/\{id\}/g, id)
                        temp = temp.replace(/\{colspan\}/g, colspan)
                        temp = temp.replace(/\{rowspan\}/g, rowspan)
                        temp = temp.replace(/id="mtgHC.*?_\{x\}"/g,'')
                        temp = temp.replace(/width="\{width\}"/g,'')
                        temp = temp.replace(/width:\{width\}px;/g,'')
                        temp = temp.replace(/height="\{height\}"/g,'')
                        temp = temp.replace(/height:\{height\}px;/g,'')
                        temp = temp.replace(/\{color\}/g, '#ddd')
                        temp = temp.replace(/\{display\}/g, display)
                        html[idx++] = temp
                        temp = ihcTmpl.replace(/\{id\}/g, id)
                        temp = temp.replace(/id="mtgIHC.*?_\{x\}"/g,'')
                        temp = temp.replace(/width:\{width\}px;/g,'')
                        temp = temp.replace(/height:\{height\}px;/g,'')
                        html[idx++] = temp
                        html[idx++] = row[j].title
                        html[idx++] = '</div>'
                        html[idx++] = '</th>'
                    x++
                # end for

                if i == 0  # Last Header Element added in nested level 0
                    temp = thTmplLast.replace(/\{id\}/g, id)
                    temp = temp.replace(/\{x\}/g, @filledPositions.length)
                    temp = temp.replace(/\{colspan\}/g, '1')
                    temp = temp.replace(/\{rowspan\}/g, rnl)
                    temp = temp.replace(/\{width\}/g, 20)
                    temp = temp.replace(/\{height\}/g, rnl*@cellHeight)
                    html[idx++] = temp
                    temp = ihcTmplLast.replace(/\{id\}/g, id)
                    temp = temp.replace(/\{height\}/g, rnl*@cellHeight-6)
                    temp = temp.replace(/\{width\}/g, 14)
                    html[idx++] = temp
                    html[idx++] = '&nbsp;'
                    html[idx++] = '</div>'
                    html[idx++] = '</th>'

                html[idx++] = '</tr>'
            # end for
            html[idx++] = '</thead>'
            html[idx++] = '</table>'
            return html.join('')

        ###
        # Retrieves the header row by nested level
        #
        # @param nl nested level
        # @param elements header elements
        ###
        _getHeaderRow : (nl, elements, column) ->
            cm = @columnModel
            elements = elements or cm
            result = []
            idx = 0
            if nl > 0
                j = 0
                children = null
                if !column
                    for i in [0...elements.length]
                        if elements[i].hasOwnProperty('children') and elements[i].children.length > 0
                            children = elements[i].children
                            result[idx++] = children[j] for j in [0...children.length]
                else
                    if column.hasOwnProperty('children') and column.children.length > 0
                        children = column.children
                        result[idx++] = children[j] for j in [0...children.length]
            else
                result = if (!column) then elements else column

            result = @_getHeaderRow(--nl, result) if nl > 0
            return result


        ###
        # Get header row nested level
        ###
        getHeaderRowNestedLevel : ->
            cm = @columnModel
            result = 0
            for column in cm
                nl = @_getHeaderColumnNestedLevel(column)
                result = nl if nl > result
            return result + 1

        ###
        # Get column nested level
        # @param column the column object
        ###
        _getHeaderColumnNestedLevel : (column) ->
            result = 0
            if column.hasOwnProperty('children') and column.children.length > 0
                result++
                max = 0
                for element in column.children
                    nl = @_getHeaderColumnNestedLevel(element)
                    max = nl if nl > max
                result = result + max
            return result


        ###
        # Get number of nested cells (used to determine colspan attribute)
        # @param column the column object
        ###
        _getNumberOfNestedCells : (column) ->
            result = 1
            if column.hasOwnProperty('children') and column.children.length > 0
                children = column.children
                result = children.length
                result = result + @_getNumberOfNestedCells(element) - 1 for element in children
            return result

        ###
        # Useful for determine index positions
        ###
        _getStartingPosition : ->
            result = 0
            while(true)
                break if @filledPositions.indexOf(result) == -1
                result++
            return result

        ###
        # Useful for determine index positions
        ###
        _getNextIndexPosition : (idx) ->
            result = idx
            while(true)
                break if @filledPositions.indexOf(result) == -1
                result++
            return result

        ###
        # Validates header columns width
        ###
        _validateHeaderColumns : ->
            cm = @columnModel
            cm[i] = @_validateHeaderColumnWidth(cm[i]) for i in [0...cm.length]  # foreach column
            @columnModel = cm


        _validateHeaderColumnWidth : (column) ->
            defaultWidth = @defaultHeaderColumnWidth
            cnl = @_getHeaderColumnNestedLevel(column)
            if cnl > 0
                cl = cnl - 1 # current level
                loop
                    elements = @_getHeaderRow(cl, null, column)
                    for i in [0...elements.length]
                        childrenWidth = 0
                        if elements[i].hasOwnProperty('children') and elements[i].children.length > 0
                            children = elements[i].children
                            for j in [0...children.length]
                                children[j].width = if children[j].width then parseInt(children[j].width) else defaultWidth
                                childrenWidth += children[j].width

                            elements[i].children = children
                        else
                            childrenWidth = if elements[i].width then parseInt(elements[i].width) else defaultWidth
                        elements[i].width = childrenWidth
                    cl--
                    break if cl <= 0
            else  # is a leaf
                column.width = if column.width then parseInt(column.width) else defaultWidth
            return column

        getTableHeaderWidth : ->
            rnl = @rnl #row nested level
            result = 0
            for i in [0...rnl] # for each nested level
                row = @_getHeaderRow(i)
                for j in [0...row.length]
                    cnl = @_getHeaderColumnNestedLevel(row[j])
                    if cnl == 0 # is a leaf element
                        result += row[j].width + 2 if row[j].visible is undefined or row[j].visible
            return result


        getTableHeaderHeight : ->
            return @rnl * (@cellHeight + 2)


        getLeafElements : ->
            rnl = @rnl #row nested level
            colspan = 1
            @filledPositions = []
            for i in [0...rnl] # for each nested level
                row = @_getHeaderRow(i)
                x = @_getStartingPosition()
                for j in [0...row.length]
                    cell = row[j]
                    cnl = @_getHeaderColumnNestedLevel(cell)
                    if cnl == 0 # is a leaf element
                        x = @_getNextIndexPosition(x)
                        @filledPositions.push(x)
                        @_leafElements[x] = cell
                    else
                        colspan = @_getNumberOfNestedCells(cell)
                        x += colspan - 1
                    x++
            return @_leafElements


    return TableGrid