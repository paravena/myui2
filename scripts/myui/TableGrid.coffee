define ['jquery', 'cs!myui/Util'], ($, Util) ->
    class TableGrid
        ###
        # TableGrid constructor
        ###
        constructor : (tableModel) ->
            @_mtgId = $('.my-tablegrid').length + 1
            @tableModel = tableModel
            @columnModel = tableModel.columnModel or []
            @rows = tableModel.rows or []
            @options = tableModel.options or {}
            @name = tableModel.name or ''
            @fontSize = 11
            @cellHeight = parseInt(@options.cellHeight) or 24
            @pagerHeight = 24
            @titleHeight = 24
            @toolbarHeight = 24
            @scrollBarWidth = 18
            @topPos = 0
            @leftPos = 0
            @selectedHCIndex = 0
            @pager = @options.pager or null
            @pager.pageParameter = @options.pager.pageParameter or 'page' if (@options.pager)
            @url = tableModel.url or null
            @request = tableModel.request or {}
            @sortColumnParameter = @options.sortColumnParameter or 'sortColumn'
            @ascDescFlagParameter = @options.ascDescFlagParameter or 'ascDescFlg'
            @sortedColumnIndex = 0
            @sortedAscDescFlg = 'ASC' # or 'DESC'
            @onCellFocus = @options.onCellFocus or null
            @onCellBlur = @options.onCellBlur or null
            @modifiedRows = [] #will contain the modified row numbers
            @afterRender = @options.afterRender or null #after rendering handler
            @onFailure = @options.onFailure or null #on failure handler
            @rowStyle = @options.rowStyle or null #row style handler
            @rowClass = @options.rowClass or null #row class handler
            @addSettingBehaviorFlg = (@options.addSettingBehavior == undefined or @options.addSettingBehavior)? true : false
            @addDraggingBehaviorFlg = (@options.addDraggingBehavior == undefined or @options.addDraggingBehavior)? true : false
            @onPageChange = @options.onPageChange or null
            @renderedRows = 0 #Use for lazy rendering
            @renderedRowsAllowed = 0 #Use for lazy rendering depends on bodyDiv height
            @newRowsAdded = []
            @deletedRows = []
    
            # Header builder
            @hb = new HeaderBuilder(@_mtgId, @columnModel)
            if @hb.getHeaderRowNestedLevel() > 1
                @addSettingBehaviorFlg = false
                @addDraggingBehaviorFlg = false

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
    
            @gap = 2 #diff between width and offsetWidth
            @gap = 0 if Prototype.Browser.WebKit


        show : (target) ->
            @render(target)

        ###
        # Renders the table grid control into a given target
        ###
        render : (target) ->
            @target = target
            $(target).innerHTML = @_createTableLayout()
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
                @_makeAllColumnDraggable() if @addDraggingBehaviorFlg
                @_applySettingMenuBehavior() if @addSettingBehaviorFlg
                @keys = new KeyTable(@)
                @_addKeyBehavior()
                @_addPagerBehavior() if @pager
                @afterRender() if @afterRender
                @_hideLoaderSpinner()
          
            f_handler = =>
                @renderedRowsAllowed = Math.floor((@bodyHeight - @scrollBarWidth - 3)  / @cellHeight) + 1
                if @tableModel.hasOwnProperty('rows')
                    @innerBodyDiv.html(@_createTableBody(@rows))
                    @pagerDiv.html(@_updatePagerInfo()) if @pager
                    @bodyDiv.trigger 'dom:dataLoaded'
                else 
                    @_retrieveDataFromUrl(1, true)
            setTimeout f_handler, 0 

            @options.toolbar = @options.toolbar or null
          
            if (@options.toolbar) 
                elements = @options.toolbar.elements or []
                if elements.indexOf(TableGrid.ADD_BTN) >= 0
                    $('#mtgAddBtn'+id).click =>
                        addFlg = true
                        if @options.toolbar.onAdd
                            addFlg = @options.toolbar.onAdd()
                            addFlg = true if addFlg is undefined 

                        if @options.toolbar.beforeAdd
                            addFlg = @options.toolbar.beforeAdd()
                            addFlg = true if addFlg is undefined 
                        
                        if addFlg
                            @addNewRow()
                            @options.toolbar.afterAdd() if @options.toolbar.afterAdd
              
                if elements.indexOf(TableGrid.DEL_BTN) >= 0
                    $('#mtgDelBtn'+id).click =>
                        deleteFlg = true
                        if @options.toolbar.onDelete
                            deleteFlg = @options.toolbar.onDelete()
                            deleteFlg = true if deleteFlg is undefined

                        if @options.toolbar.beforeDelete
                            deleteFlg = @options.toolbar.beforeDelete()
                            deleteFlg = true if deleteFlg is undefined

                        if deleteFlg
                            @deleteRows()
                            @options.toolbar.afterDelete() if @options.toolbar.afterDelete

                if elements.indexOf(TableGrid.SAVE_BTN) >= 0
                    $('#mtgSaveBtn'+id).click =>
                        @_blurCellElement(@keys._nCurrentFocus)
                        @options.toolbar.onSave() if @options.toolbar.onSave
            
            # Adding scrolling handler
            f_scroll = => @_syncScroll()
            @bodyDiv.bind 'scroll', f_scroll 
            # Adding resize handler
            f_resize = => @resize() 
            $(window).bind 'resize', f_resize

        ###
        # Creates the table layout
        ###
        _createTableLayout : ->
            target = $(@target)
            width = @options.width or (target.getWidth() - @_fullPadding(target,'left') - @_fullPadding(target,'right')) + 'px'
            height = @options.height or (target.getHeight() - @_fullPadding(target,'top') - @_fullPadding(target,'bottom') + 2) + 'px'
            id = @_mtgId
            overlayTopPos = 0
            overlayHeight = 0
            @tableWidth = parseInt(width) - 2
            overlayHeight = @tableHeight = parseInt(height) - 2

            idx = 0
            html = []
            html[idx++] = '<div id="myTableGrid'+id+'" class="my-tablegrid" style="position:relative;width:'+@tableWidth+'"px;height:'+@tableHeight+'px;z-index:0">'

            if @options.title # Adding header title
                html[idx++] = '<div id="mtgHeaderTitle'+id+'" class="my-tablegrid-header-title" style="position:absolute;top:'+@topPos+'px;left:'+@leftPos+'px;width:'+(@tableWidth - 6)+'px;height:'+(@titleHeight - 6)+'px;padding:3px;z-index:10">'
                html[idx++] = @options.title
                html[idx++] = '</div>'
                @topPos += @titleHeight + 1


            if @options.toolbar
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
            @bodyHeight = @bodyHeight - @titleHeight - 1 if @options.title
            @bodyHeight = @bodyHeight - @pagerHeight - 1 if @options.pager
            @bodyHeight = @bodyHeight - @toolbarHeight - 1 if @options.toolbar
            overlayHeight = @bodyHeight + @headerHeight

            html[idx++] = '<div id="overlayDiv'+id+'" class="overlay" style="position:absolute;top:'+overlayTopPos+'px;width:'+(@tableWidth+2)+'px;height:'+(overlayHeight+2)+'px;overflow:none;">'
            html[idx++] = '<div class="loadingBox" style="margin-top:'+((overlayHeight+2) / 2 - 14)+'px">'+i18n.getMessage('label.loading')+'</div>'
            html[idx++] = '</div>' # closes overlay
            html[idx++] = '<div id="bodyDiv'+id+'" class="my-tablegrid-body" style="position:absolute;top:'+@topPos+'px;left:'+@leftPos+'px;width:'+@tableWidth+'px;height:'+@bodyHeight+'px;overflow:auto;">'
            html[idx++] = '<div id="innerBodyDiv'+id+'" class="my-tablegrid-inner-body" style="position:relative;top:0px;width:'+(@tableWidth - @scrollBarWidth)+'px;overflow:none;">'
            html[idx++] = '</div>' # closes innerBodyDiv
            html[idx++] = '</div>' # closes bodyDiv

            # Adding Pager Panel
            if @pager
                @topPos += @bodyHeight + 2
                html[idx++] = '<div id="pagerDiv'+id+'" class="my-tablegrid-pager" style="position:absolute;top:'+@topPos+'px;left:0;bottom:0;width:'+(@tableWidth - 4)+'px;height:'+(@pagerHeight - 4)+'px">'
                html[idx++] = @_updatePagerInfo(true)
                html[idx++] = '</div>' # closes Pager Div

            # Adding Table Setting Button Control
            if @addSettingBehaviorFlg
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
            cellHeight = @cellHeight
            headerWidth = @headerWidth
            html = []
            idx = 0
            firstRenderingFlg = false
            firstRenderingFlg = true if (renderedRows == 0)

            if firstRenderingFlg
                @innerBodyDiv.css 'height',  (rows.length * cellHeight) + 'px'
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
            tdTmpl = '<td id="mtgC{id}_{x},{y}" height="{height}" width="{width}" style="width:{width}px;height:{height}px;padding:0;margin:0;display:{display}" class="my-tablegrid-cell mtgC{id} mtgC{id}_{x} mtgR{id}_{y}">'
            icTmpl = '<div id="mtgIC{id}_{x},{y}" style="width:{width}px;height:{height}px;padding:3px;text-align:{align}" class="my-tablegrid-inner-cell mtgIC{id} mtgIC{id}_{x} mtgIR{id}_{y}">'
            checkboxTmpl = '<input id="mtgInput{id}_{x},{y}" name="mtgInput{id}_{x},{y}" type="checkbox" value="{value}" class="mtgInput{id}_{x} mtgInputCheckbox" checked="{checked}">'
            radioTmpl = '<input id="mtgInput{id}_{x},{y}" name="mtgInput{id}_{x}" type="radio" value="{value}" class="mtgInput{id}_{x} mtgInputRadio">'
            if Prototype.Browser.Opera or Prototype.Browser.WebKit
                checkboxTmpl = '<input id="mtgInput{id}_{x},{y}" name="mtgInput{id}_{x},{y}" type="checkbox" value="{value}" class="mtgInput{id}_{x}" checked="{checked}">'
                radioTmpl = '<input id="mtgInput{id}_{x},{y}" name="mtgInput{id}_{x}" type="radio" value="{value}" class="mtgInput{id}_{x}">'

            rs = @rowStyle or ( ->  return '') # row style handler
            rc = @rowClass or ( ->  return '') # row class handler
            cellHeight = @cellHeight
            iCellHeight = cellHeight - 6
            cm = @columnModel
            gap = if @gap == 0 then 2 else 0
            html = []
            idx = 0
            html[idx++] = '<tr id="mtgRow'+id+'_'+rowIdx+'" class="mtgRow'+id+' '+rc(rowIdx)+'" style="'+rs(rowIdx)+'">'
            for j in [0...cm.length]
                columnId = cm[j].id
                type = cm[j].type or 'string'
                cellWidth = parseInt(cm[j].width) # consider border at both sides
                iCellWidth = cellWidth - 6 - gap # consider padding at both sides
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

        _toggleLoadingOverlay : ->
            id = @_mtgId
            overlayDiv = $('#overlayDiv'+id)
            if overlayDiv.css('visibility') == 'hidden'
                @_hideMenus()
                overlayDiv.css('visibility', 'visible')
            else
                overlayDiv.css('visibility', 'hidden')

        ###
        # Applies cell callbacks
        ###
        _applyCellCallbacks : ->
            renderedRows = @renderedRows
            renderedRowsAllowed = @renderedRowsAllowed
            beginAtRow = renderedRows - renderedRowsAllowed
            beginAtRow = 0 if beginAtRow < 0
            @_applyCellCallbackToRow(j) for j in [beginAtRow...renderedRows]

        _applyCellCallbackToRow : ->
            id = @_mtgId
            cm = @columnModel
            for i in [0...cm.length]
                editor = cm[i].editor
                if (editor == 'radio' or editor instanceof TableGrid.CellRadioButton) or
                   (editor == 'checkbox' or editor instanceof TableGrid.CellCheckbox)
                    element = $('#mtgInput'+id + '_' + i + ',' + y)
                    innerElement = $('#mtgIC'+id + '_' + i + ',' + y)
                    f_handler = (editor, element, innerElement) =>
                        return ( ->
                                if editor.selectable is undefined or !editor.selectable
                                    coords = element.attr('id').substring(element.id.indexOf('_') + 1, element.attr('id').length).split(',')
                                    x = coords[0];
                                    y = coords[1];
                                    value = element.is(':checked')
                                    value = editor.getValueOf(element.checked) if editor.hasOwnProperty('getValueOf')
                                    @setValueAt(value, x, y, false);
                                    @modifiedRows.push(y) if y >= 0 and @modifiedRows.indexOf(y) == -1  # if doesn't exist in the array the row is registered
                                )
                    elementClickHandler = f_handler(editor, element, innerElement)
                    editor.onClickCallback(element.value, element.checked) if editor.onClickCallback
                    innerElement.addClass('modified-cell') if editor.selectable is undefined or !editor.selectable
                    element.click elementClickHandler

        getId : ->
            return @_mtgId

        _showLoaderSpinner : ->
            id = @_mtgId
            loaderSpinner = $('#mtgLoader'+id)
            loaderSpinner.show() if(loaderSpinner)

        _hideLoaderSpinner : ->
            id = @_mtgId
            loaderSpinner = $('#mtgLoader'+id)
            loaderSpinner.hide() if(loaderSpinner)


        _hideMenus : ->
            id = @_mtgId
            hb = $('#mtgHB'+id)
            hbm = $('#mtgHBM'+id)
            sm = $('#mtgSM'+id)
            hb.css('visibility','hidden') if (hb)
            hbm.css('visibility','hidden') if (hbm)
            sm.css('visibility','hidden') if (sm)

        ###
        # Creates the Setting Menu
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
            for i in [0...cm.length]
                column = cm[i]
                html[idx++] = '<li>'
                html[idx++] = '<a href="#" class="my-tablegrid-menu-item">'
                html[idx++] = '<table border="0" cellpadding="0" cellspacing="0" width="100%">'
                html[idx++] = '<tr><td width="25"><span><input id="'+column.id+'" type="checkbox" checked="'+column.visible+'"></span></td>'
                html[idx++] = '<td><label for="'+column.id+'">&nbsp;'+ column.title+'</label></td></tr>'
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
            settingMenu = $('#mtgSM' + @_mtgId)
            settingButton = $('#mtgSB' + @_mtgId)
          
            width = settingMenu.width()
          
            settingButton.click ->
                if settingMenu.css('visibility') == 'hidden'
                    topPos = settingButton.offsetTop  #TODO check this
                    leftPos = settingButton.offsetLeft #TODO check this
                    settingMenu.css({
                        'top' : (topPos + 16) + 'px',
                        'left' : (leftPos - width + 16) + 'px',
                        'visibility' : 'visible'
                    })
                else
                    settingMenu.css('visibility', 'hidden')

            miFlg = false
            settingMenu.mousemove ->
                miFlg = true

            settingMenu.mouseout (event) ->
                miFlg = false
                element = $(event.target)
                f_timeout = ->
                    if !element.parent(settingMenu) and !miFlg
                        settingMenu.css('visibility', 'hidden')
                setTimeout f_timeout, 500
            i = 0
            for checkbox in $('#mtgSM'+@_mtgId + ' input')
                $(checkbox).click =>
                   @_toggleColumnVisibility(i++, checkbox.checked)

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

            @scrollLeft = headerRowDiv.scrollLeft = bodyDiv.scrollLeft # TODO check this
            @scrollTop = bodyDiv.scrollTop # TODO check this

            $('mtgHB' + id).css('visibility', 'hidden')

            if renderedRows < @rows.length and (bodyTable.height() - bodyDiv.scrollTop - 10) < bodyDiv.clientHeight # TODO check this
                html = @_createTableBody(@rows)
                bodyTable.find('tbody').append(html)
                @_addKeyBehavior()
                @_applyCellCallbacks()
                keys.addMouseBehavior()


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
            for separator in $('.mtgHS' + @_mtgId)
                separator.mousemove =>
                    columnIndex = parseInt(separator.attr('id').substring(separator.attr('id').indexOf('_') + 1, separator.attr('id').length))
                    if columnIndex >= 0
                        leftPos = $('#mtgHC' + id + '_' + columnIndex).offsetLeft - @scrollLeft
                        leftPos += $('#mtgHC' + id + '_' + columnIndex).offsetWidth - 1
                        @resizeMarkerRight.css({
                            'height' : (@bodyHeight + headerHeight) + 'px',
                            'top' : (topPos + 2) + 'px',
                            'left' : leftPos + 'px'
                        })

            # TODO I need to change this, maybe with jquery++
            new Draggable(@resizeMarkerRight, {
                constraint : 'horizontal'
                onStart : ->
                    markerHeight = @bodyHeight + headerHeight + 2
                    markerHeight = markerHeight - scrollBarWidth + 1 if @_hasHScrollBar()
                    @resizeMarkerRight.css({
                        'height' : markerHeight + 'px',
                        'background-color' : 'dimgray'
                    })

                    leftPos = $('#mtgHC' + id + '_' + columnIndex).offsetLeft - @scrollLeft

                    @resizeMarkerLeft.css({
                        'height' : markerHeight + 'px',
                        'top' : (topPos + 2) + 'px',
                        'left' : leftPos + 'px',
                        'background-color' : 'dimgray'
                    })

                onEnd : ->
                    newWidth = parseInt(@resizeMarkerRight.css('left')) - parseInt(@resizeMarkerLeft.css('left'))
                    if newWidth > 0 and columnIndex != null
                        setTimeout(( ->
                            @_resizeColumn(columnIndex, newWidth)
                        ), 0)

                    @resizeMarkerLeft.css({
                        'backgroundColor' : 'transparent',
                        'left' : '0'
                    })
        
                    @resizeMarkerRight.css('background-color', 'transparent')

                endeffect : false
            })


        ###
        # Resizes a column to a new size
        #
        # @param index the index column position
        # @param newWidth resizing width
        ###
        _resizeColumn: (index, newWidth) ->
            id = @_mtgId
            cm = @columnModel
            gap = @gap

            oldWidth = parseInt($('mtgHC' + id + '_' + index).attr('width'))
            editor = cm[index].editor
            checkboxOrRadioFlg = editor == 'checkbox' or editor instanceof TableGrid.CellCheckbox or editor == 'radio' or editor instanceof TableGrid.CellRadioButton

            $('#mtgHC' + id + '_' + index).attr('width', newWidth)
            $('#mtgHC' + id + '_' + index).css('width', newWidth + 'px')
            $('#mtgIHC' + id + '_' + index).css('width', (newWidth - 8 - (if gap == 0 then 2 else 0)) + 'px')

            for cell in $('.mtgC' + id + '_' + index)
                cell.attr('width', newWidth)
                cell.css('width', newWidth + 'px')


            for cell in $('.mtgIC' + id + '_' + index)
                cellId = cell.id
                coords = cellId.substring(cellId.indexOf('_') + 1, cellId.length).split(',')
                y = coords[1]
                value = @getValueAt(index, y)
                cell.setStyle({width: (newWidth - 6 - (if gap == 0 then 2 else 0)) + 'px'})
                if !checkboxOrRadioFlg
                    if cm[index].renderer
                        if editor instanceof ComboBox
                            value = cm[index].renderer(value, editor.getItems(), @getRow(y))
                        else
                            value = cm[index].renderer(value, @getRow(y))
                    cell.html(value)

            @headerWidth = @headerWidth - (oldWidth - newWidth)

            $('#mtgHRT' + id).attr('width', @headerWidth + 21)
            $('#mtgBT' + id).attr('width', @headerWidth)
          
            @columnModel[index].width = newWidth
            @_syncScroll()

        _hasHScrollBar : ->
            return @headerWidth + 20 > @tableWidth

        ###
        # Makes all columns draggable
        ###
        _makeAllColumnDraggable : ->
            @separators = []
            i = 0
            id = @_mtgId
            for separator in $('.mtgHS' + @_mtgId)
                @separators[i++] = separator

            topPos = 0
            topPos += @titleHeight if @options.title
            topPos += @toolbarHeight if @options.toolbar
          
            dragColumn = $('#dragColumn' + id)
          
            for column in $('.mtgIHC' + id)
                columnIndex = -1
                column.on  'mousemove', ->
                    leftPos = column.parent().position().left
                    dragColumn.css({
                        top: (topPos + 15) + 'px',
                        left: (leftPos - @scrollLeft + 15) + 'px'
                    })
                # TODO check this
                new Draggable(dragColumn, {
                    handle : column,
                    onStart : ->
                        for i in [0...@columnModel.length]
                            if index == @columnModel[i].positionIndex
                                columnIndex = i
                                break
                        dragColumn.find('span').html(@columnModel[columnIndex].title)
                        dragColumn.css('visibility', 'visible')
                    onDrag : ->
                        leftPos = parseInt(dragColumn.css('left'))
                        width = parseInt(dragColumn.css('width'))
                        setTimeout(( ->
                            @_detectDroppablePosition(leftPos + width / 2, width, dragColumn, columnIndex)
                        ), 0)
                    onEnd : ->
                        dragColumn.css('visibility', 'hidden')
                        @colMoveTopDiv.css('visibility', 'hidden')
                        @colMoveBottomDiv.css('visibility', 'hidden')
                        if columnIndex >= 0 and @targetColumnId >= 0
                            setTimeout(( ->
                                @_moveColumn(columnIndex, @targetColumnId)
                                columnIndex = -1
                            ), 0)
                    endeffect : false
                })

        ###
        # Detects droppable position when the mouse pointer is over a header cell
        # separator
        ###
        _detectDroppablePosition : (columnPos, width, dragColumn, index) ->
            topPos = -10
            topPos += @headerHeight if (@options.title)
            topPos += @headerHeight if (@options.toolbar)
            sepLeftPos = 0
            cm = @columnModel
            gap = @gap
            scrollLeft = @scrollLeft
            colMoveTopDiv = @colMoveTopDiv
            colMoveBottomDiv = @colMoveBottomDiv
          
            for i in [0...cm.length]
                sepLeftPos += parseInt(cm[i].width) + gap if (cm[i].visible)
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
                    dragColumn.find('div').addClass( if i != index then 'drop-yes' else 'drop-no') # TODO check this
                    break
                else
                    colMoveTopDiv.css('visibility', 'hidden')
                    colMoveBottomDiv.css('visibility', 'hidden')
                    @targetColumnId = null
                    dragColumn.find('div').addClass('drop-no') # TODO check this

        test: ->
            alert 'test method'


    TableGrid.ADD_BTN = 1
    TableGrid.DEL_BTN = 4
    TableGrid.SAVE_BTN = 8

    class HeaderBuilder
        constructor: (id, cm) ->
            @columnModel = cm
            @_mtgId = id
            @gap = 2 #diff between width and offsetWidth
            @gap = 0 if Prototype.Browser.WebKit
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
            thTmpl = '<th id="mtgHC{id}_{x}" colspan="{colspan}" rowspan="{rowspan}" width="{width}" height="{height}" style="position:relative;width:{width}px;height:{height}px;padding:0;margin:0;border-bottom-color:{color};display:{display}" class="my-tablegrid-header-cell mtgHC{id}">'
            thTmplLast = '<th id="mtgHC{id}_{x}" colspan="{colspan}" rowspan="{rowspan}" width="{width}" height="{height}" style="width:{width}px;height:{height}px;padding:0;margin:0;border-right:none;border-bottom:1px solid #ccc;" class="my-tablegrid-header-cell mtgHC{id}">'
            ihcTmpl = '<div id="mtgIHC{id}_{x}" class="my-tablegrid-inner-header-cell mtgIHC{id}" style="float:left;width:{width}px;height:{height}px;padding:4px 3px;z-index:20">'
            ihcTmplLast = '<div class="my-tablegrid-inner-header-cell" style="position:relative;width:{width}px;height:{height}px;padding:3px;z-index:20">'
            hsTmpl = '<div id="mtgHS{id}_{x}" class="mtgHS mtgHS{id}" style="float:right;width:1px;height:{height}px;z-index:30">'
            siTmpl = '<span id="mtgSortIcon{id}_{x}" style="width:8px;height:4px;visibility:hidden">&nbsp;&nbsp;&nbsp;</span>'
            cm = @columnModel
            id = @_mtgId
            gap = if @gap == 0 then 2 else 0
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
                        temp = temp.replace(/\{width\}/g,  cellWidth - 8 - gap)
                        temp = temp.replace(/\{height\}/g, cell.height - 6 - gap)
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
            gap = @gap
            rnl = @rnl #row nested level
            result = 0
            for i in [0...rnl] # for each nested level
                row = @_getHeaderRow(i)
                for j in [0...row.length]
                    cnl = @_getHeaderColumnNestedLevel(row[j])
                    if cnl == 0 # is a leaf element
                        result += row[j].width + gap if row[j].visible is undefined or row[j].visible
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