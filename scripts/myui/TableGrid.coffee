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
          
            $('mtgHB' + id).css('visibility', 'hidden') # in case the cell menu button is visible
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
                removedHeaderCell = $('mtgHC'+id+'_'+fromColumnId).remove()
                targetHeaderCell = $('mtgHC'+id+'_'+ toColumnId)
                targetHeaderCell.up().insertBefore(removedHeaderCell, targetHeaderCell)
              
                # Moving cell elements
                removedCells = []
                idx = 0
                for element in $('.mtgC' + id + '_' + fromColumnId)
                    removedCells[idx++] = element.remove()

              
                if numberOfRowsAdded > 0
                    for i in [-numberOfRowsAdded...0]
                        targetCell = $('#mtgC'+id+'_'+toColumnId+','+i)
                        targetCell.parent().insertBefore(removedCells[i+numberOfRowsAdded], targetCell)

                for i in [numberOfRowsAdded...(renderedRows+numberOfRowsAdded)]
                    targetCell = $('#mtgC'+id+'_'+toColumnId+','+(i-numberOfRowsAdded))
                    targetCell.parent().insertBefore(removedCells[i], targetCell)

            else if toColumnId > 0 and toColumnId < cm.length - 1 # moving in between
                removedHeaderCell = $('#mtgHC' + id + '_' + fromColumnId).remove()
                targetId = toColumnId + 1
                targetId-- if targetId == fromColumnId
                targetHeaderCell = $('mtgHC'+id+'_'+ targetId)
                targetHeaderCell.up().insertBefore(removedHeaderCell, targetHeaderCell)
              
                # Moving cell elements
                removedCells = []
                idx = 0
                for element in $('.mtgC' + id + '_' + fromColumnId)
                    removedCells[idx++] = element.remove()

                if (numberOfRowsAdded > 0)
                    for i in [-numberOfRowsAdded...0]
                        targetCell = $('#mtgC' + id + '_' + targetId +',' + i)
                        targetCell.parent().insertBefore(removedCells[i+numberOfRowsAdded], targetCell)


                for i in [numberOfRowsAdded...(renderedRows+numberOfRowsAdded)]
                    targetCell = $('#mtgC' + id + '_' + targetId + ',' + (i-numberOfRowsAdded))
                    targetCell.parent().insertBefore(removedCells[i], targetCell)

            else if toColumnId == cm.length - 1 # moving to the last column
                tr = $('#mtgHC' + id + '_' + fromColumnId).parent()
                removedHeaderCell = $('mtgHC' + id + '_' + fromColumnId).remove()
                last = $('mtgHC' + id + '_' + cm.length)
                tr.insertBefore(removedHeaderCell, last)
              
                # Moving cell elements
                removedCells = []
                idx = 0;
                for element in $('.mtgC' + id + '_' + fromColumnId)
                    removedCells[idx++] = element.remove()

                if (numberOfRowsAdded > 0)
                    for i in [-numberOfRowsAdded...0]
                        tr = $('mtgRow' + id + '_' + i)
                        tr.append(removedCells[i+numberOfRowsAdded])

                for i in [umberOfRowsAdded...(renderedRows+numberOfRowsAdded)]
                    tr = $('#mtgRow' + id + '_' + (i-numberOfRowsAdded))
                    tr.append(removedCells[i])

            # Update column model
            columnModelLength = cm.length
            columnModelEntry = cm[fromColumnId]
            cm[fromColumnId] = null
            cm = cm.compact()
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
                    th.id = 'mtgHC'+ id + '_' + index
                    try
                        ihc = th.find('div.my-tablegrid-inner-header-cell')
                        ihc.attr('id', 'mtgIHC' + id + '_' + index)
                        ihc.find('span').attr('id', 'mtgSortIcon' + id + '_' + index)
                        hs = th.find('div.mtgHS')
                        hs.attr('id', 'mtgHS' + id + '_' + index)
                    catch ihc_ex
                        # exception of ihc.down('div') being non existant

            # Recreates cell indexes
            for i in [-numberOfRowsAdded...renderedRows]
                $('.mtgR'+id+'_'+i).each (index, td) ->
                    td.attr('id', 'mtgC' + id + '_' + index + ',' + i)
                    td.attr('class', 'my-tablegrid-cell mtgC' + id + ' mtgC' + id + '_' + index + ' mtgR' + id + '_' + i)

                $('.mtgIR'+id+'_'+i).each (index, div) ->
                    div.attr('id', 'mtgIC' + id + '_' + index + ',' + i)
                    modifiedCellClass = if div.attr('class').match(/modified-cell/) then ' modified-cell' else ''
                    div.attr('class', 'my-tablegrid-inner-cell mtgIC' + id + ' mtgIC' + id + '_' + index + ' mtgIR' + id + '_' + i + modifiedCellClass)
                    if div.first() and div.first().is('INPUT')  # when it contains a checkbox or radio button
                        input = div.first()
                        input.attr('id', 'mtgInput' + id + '_' + index + ',' + i)
                        input.attr('name', 'mtgInput' + id + '_' + index + ',' + i)
                        # input.className =  input.className.replace(/mtgInput.*?_.*?\s/, 'mtgInput'+id+'_'+index+' ')
                        input.attr('class', 'mtgInput' + id + '_' + index)

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
            for j in [beginAtRow...renderedRows]
                @_addKeyBehaviorToRow(rows[j], j)

        _addKeyBehaviorToRow : (row, j) ->
            id = @_mtgId
            cm = @columnModel
            keys = @keys
          
            for i in [0...cm.length]
                element = $('#mtgC' + id + '_' + i + ',' + j)
                if cm[i].editable
                    keys.event.remove.action(element)
                    keys.event.remove.esc(element)
                    keys.event.remove.blur(element)
                  
                    f_action = ((element) =>
                        return ->
                            if @editedCellId == null or @editedCellId != element.attr('id')
                                @editedCellId = element.attr('id')
                                @_editCellElement(element)
                            else
                                @editedCellId = null if @_blurCellElement(element)

                    )(element)
                    keys.event.action(element, f_action)
                  
                    f_esc = ((element) =>
                        return ->
                            @editedCellId = null if @_blurCellElement(element)
                    )(element)
                    keys.event.esc(element, f_esc)
                  
                    f_blur = ((x, y, element) =>
                        return ->
                            @editedCellId = null if @_blurCellElement(element)
                            @onCellBlur(element, row[x], x, y, cm[x].id) if (@onCellBlur)
                    )(i, j, element)
                    keys.event.blur(element, f_blur)

                keys.event.remove.focus(element)
                f_focus = ((x, y, element) =>
                    return ->
                        @onCellFocus(element, row[x], x, y, cm[x].id) if @onCellFocus
                )(i, j, element)
                keys.event.focus(element, f_focus);

        ###
        # When a cell is edited
        ###
        _editCellElement : (element) ->
            @keys._bInputFocused = true
            cm = @columnModel
            coords = @getCurrentPosition()
            x = coords[0]
            y = coords[1]
            width = parseInt(element.css('width'))
            height = parseInt(element.css('height'))
            innerElement = element.find('div') # TODO check this
            value = @getValueAt(x, y)
            editor = @columnModel[x].editor or 'input'
            input = null
            isInputFlg = !(editor == 'radio' or editor == 'checkbox' or editor instanceof TableGrid.CellCheckbox or editor instanceof TableGrid.CellRadioButton)
          
            if isInputFlg
                element.css('height', @cellHeight + 'px')
                innerElement.css({
                    'position': 'relative',
                    'width': width + 'px',
                    'height': height + 'px',
                    'padding': '0',
                    'border': '0',
                    'margin': '0'
                })
                innerElement.html('')
                value = cm[x].renderer(value, editor.getItems(), @getRow(y)) if editor instanceof ComboBox # when is a list
                # Creating a normal input
                inputId = 'mtgInput' + @_mtgId + '_' + x + ',' + y
                input = $('input').attr({'id' : inputId, 'type' : 'text', 'value' : value})
                input.addClass('my-tablegrid-textfield')
                input.css({
                    'padding' : '3px',
                    'width' : (width - 8) + 'px'
                })
                innerElement.append(input)
                editor.setTableGrid(this)
                editor.render(input)
                editor.validate() if editor.validate
                input.focus()
                input.select()
            else if editor == 'checkbox' or editor instanceof TableGrid.CellCheckbox
                input = $('#mtgInput' + @_mtgId + '_' + x + ',' + y)
                input.attr('checked', !input.is(':checked')) # TODO check this weird thing
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
                input = $('#mtgInput' + @_mtgId + '_' + x + ',' + y)
                input.attr('checked', !input.is(':checked')) # TODO check this weird thing
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
            id = @_mtgId
            keys = @keys
            cm = @columnModel
            width = parseInt(element.css('width'))
            height = parseInt(element.css('height'))
            coords = @getCurrentPosition()
            x = coords[0]
            y = coords[1]
            cellHeight = @cellHeight
            innerId = '#mtgIC' + id + '_' + x + ',' + y
            input = $('#mtgInput' + id + '_' + x + ',' + y)
            innerElement = $(innerId)
            value = input.val()
            editor = cm[x].editor or 'input'
            type = cm[x].type or 'string'
            columnId = cm[x].id
            alignment = if (type == 'number') then 'right' else 'left'
          
            isInputFlg = !(editor == 'radio' or editor == 'checkbox' or editor instanceof TableGrid.CellCheckbox or editor instanceof TableGrid.CellRadioButton)
            if isInputFlg
                editor.hide() if editor.hide # this only happen when editor is a Combobox
                return false if editor instanceof DatePicker and editor.visibleFlg
                editor.reset() if editor.reset
                element.css('height', cellHeight + 'px')
                innerElement.css({
                    'width' : (width - 6) + 'px',
                    'height' : (height - 6) + 'px',
                    'padding' : '3px',
                    'text-align' : alignment
                }).html(value)

            # I hope I can find a better solution
            value = editor.getSelectedValue(value) if editor instanceof Autocompleter

            if y >= 0 and @rows[y][columnId] != value
                @rows[y][columnId] = value
                innerElement.addClass('modified-cell')
                @modifiedRows.push(y) if @modifiedRows.indexOf(y) == -1 # if doesn't exist in the array the row is registered
            else if y < 0
                @newRowsAdded[Math.abs(y)-1][columnId] = value
            #end if
            editor.afterUpdateCallback(element, value) if (editor instanceof BrowseInput or editor instanceof TextField or editor instanceof DatePicker) and editor.afterUpdateCallback
            keys._bInputFocused = false
            return true

        ###
        # Applies header buttons
        ###
        _applyHeaderButtons : ->
            id = @_mtgId
            headerHeight = @headerHeight
            headerButton = $('#mtgHB' + @_mtgId)
            headerButtonMenu = $('#mtgHBM' + @_mtgId)
            sortAscMenuItem = $('#mtgSortAsc'+@_mtgId)
            sortDescMenuItem = $('#mtgSortDesc'+@_mtgId)
            topPos = 0
            topPos += @titleHeight if @options.title
            topPos += @toolbarHeight if @options.toolbar
            selectedHCIndex = -1
            for element in $('.mtgIHC' + id)
                editor = null
                sortable = true
                hbHeight = null
                element.on 'mousemove', =>
                    cm = @columnModel;
                    return if !element.attr('id')
                    selectedHCIndex = parseInt(element.attr('id').substring(element.attr('id').indexOf('_') + 1, element.attr('id').length))
                    editor = cm[selectedHCIndex].editor
                    sortable = cm[selectedHCIndex].sortable
                    hbHeight = cm[selectedHCIndex].height
                    if sortable or editor == 'checkbox' or editor instanceof TableGrid.CellCheckbox
                        hc = element.parent()
                        leftPos = hc.offsetLeft + hc.offsetWidth
                        leftPos = leftPos - 16 - @scrollLeft
                        if leftPos < @bodyDiv.clientWidth
                            headerButton.css({
                                'top' : (topPos + 3 + headerHeight - hbHeight) + 'px',
                                'left' : leftPos + 'px',
                                'height' : hbHeight + 'px',
                                'visibility' : 'visible'
                            })

                        sortAscMenuItem.on 'click', => @_sortData(selectedHCIndex, 'ASC')
                        sortDescMenuItem.on 'click', => @_sortData(selectedHCIndex, 'DESC')

                # Sorting when click on header column
                element.on 'click', =>
                    return unless element.attr('id')
                    selectedHCIndex = parseInt(element.attr('id').substring(element.attr('id').indexOf('_') + 1, element.attr('id').length))
                    @_toggleSortData(selectedHCIndex)

            headerButton.on 'click', =>
                cm = @columnModel
                if headerButtonMenu.css('visibility') == 'hidden'
                    if cm[selectedHCIndex].sortable
                        $('mtgSortDesc' + @_mtgId).show()
                        $('mtgSortAsc' + @_mtgId).show()
                    else
                        $('mtgSortDesc' + @_mtgId).hide()
                        $('mtgSortAsc' + @_mtgId).hide()

                    selectAllItem = $('#mtgHBM' + id + ' .mtgSelectAll:first')  # TODO check this
                    if @renderedRows > 0 and (cm[selectedHCIndex].editor == 'checkbox' or cm[selectedHCIndex].editor instanceof TableGrid.CellCheckbox)
                        selectAllItem.find('input').attr('checked', cm[selectedHCIndex].selectAllFlg)
                        selectAllItem.show()
                        selectAllHandler = => # onclick handler
                            flag = cm[selectedHCIndex].selectAllFlg = $('#mtgSelectAll' + id).is(':checked')
                            selectableFlg = false
                            selectableFlg = true if cm[selectedHCIndex].editor instanceof TableGrid.CellCheckbox and cm[selectedHCIndex].editor.selectable
                            renderedRows = @renderedRows
                            beginAtRow = 0
                            beginAtRow = -@newRowsAdded.length if @newRowsAdded.length > 0
                            x = selectedHCIndex
                            for y in [beginAtRow...renderedRows]
                                element = $('#mtgInput' + id + '_' + x +','+y)
                                element.attr('checked', flag)
                                value = flag
                                if !selectableFlg
                                    value = cm[x].editor.getValueOf(element.is(':checked')) if cm[x].editor.hasOwnProperty('getValueOf')
                                    @setValueAt(value, x, y, false)
                                    # if doesn't exist in the array the row is registered
                                    @modifiedRows.push(y) if y >= 0 and @modifiedRows.indexOf(y) == -1
                        # TODO review this
                        selectAllItem.on 'click', selectAllHandler
                    else
                        selectAllItem.hide()

                    leftPos = parseInt(headerButton.css('left'))
                    topPos = @headerHeight + 2
                    topPos += @titleHeight if @options.title
                    topPos += @toolbarHeight if @options.toolbar
                    headerButtonMenu.css({
                        'top' : topPos + 'px',
                        'left' : leftPos + 'px',
                        'visibility' : 'visible'
                    })
                else
                    headerButtonMenu.css('visibility', 'hidden')

            miFlg = false
            headerButtonMenu.on 'mousemove', -> miFlg = true

            headerButtonMenu.on 'mouseout', (event) ->
                miFlg = false
                element = $(event.target)
                setTimeout(( ->
                    headerButtonMenu.css('visibility', 'hidden') if !element.closest(headerButtonMenu) and !miFlg # TODO check this
                ), 500)

        _sortData : (idx, ascDescFlg) ->
            cm = @columnModel
            id = @_mtgId
            if cm[idx].sortable
                $('#mtgSortIcon'+id+'_'+idx).attr('class', if (ascDescFlg == 'ASC') then 'my-tablegrid-sort-asc-icon' else 'my-tablegrid-sort-desc-icon')
                @request[@sortColumnParameter] = cm[idx].id;
                @request[@ascDescFlagParameter] = ascDescFlg;
                @_retrieveDataFromUrl(1)
                $('#mtgSortIcon'+id+'_'+@sortedColumnIndex).css('visibility', 'hidden')
                $('#mtgIHC'+id+'_'+@sortedColumnIndex).css('color', 'dimgray')
                $('#mtgSortIcon'+id+'_'+idx).css('visibility', 'visible')
                $('#mtgIHC'+id+'_'+idx).css('color', 'black')
                @sortedColumnIndex = idx
                cm[idx].sortedAscDescFlg = ascDescFlg

        _toggleSortData : (idx) ->
            cm = @columnModel
            if cm[idx].sortedAscDescFlg == 'DESC'
                @_sortData(idx, 'ASC')
            else
                @_sortData(idx, 'DESC')

        _toggleColumnVisibility : (index, visibleFlg) ->
            @_blurCellElement(@keys._nCurrentFocus) # in case there is a cell in editing mode
            @keys.blur() #remove the focus of the selected cell
            headerRowTable = $('#mtgHRT' + @_mtgId)
            bodyTable = $('#mtgBT' + @_mtgId)

            for i in [0...@columnModel.length]
                if @columnModel[i].positionIndex == index
                    index = i
                    break

            targetColumn = $('#mtgHC' + @_mtgId + '_' + index)
            $('#mtgHB' + @_mtgId).css('visibility', 'hidden')
            width = 0

            if !visibleFlg  # hide
                width = parseInt(targetColumn.offsetWidth)
                targetColumn.hide()
                element.hide() for element in $('.mtgC'+@_mtgId+ '_'+index)
                @columnModel[index].visible = false
                @headerWidth = @headerWidth - width
            else # show
                targetColumn.show()
                width = parseInt(targetColumn.offsetWidth) + 2
                element.show() for element in $('.mtgC'+@_mtgId+ '_'+index)
                @columnModel[index].visible = true
                @headerWidth = @headerWidth + width

            headerRowTable.attr('width', @headerWidth + 21)
            bodyTable.attr('width', @headerWidth)
            bodyTable.css('width', @headerWidth + 'px')

        _fullPadding : (element, s) ->
            padding = parseInt(element.css('padding-'+s))
            padding = if isNaN(padding) then 0 else padding
            border = parseInt(element.css('border-'+s+'-width'))
            border = if isNaN(border) then 0 else border
            return padding + border

        _retrieveDataFromUrl : (pageNumber, firstTimeFlg) ->
            return if !firstTimeFlg and @onPageChange amd !@onPageChange()
            pageParameter = 'page'
            pageParameter = @pager.pageParameter if @pager != null and @pager.pageParameter
            @request[pageParameter] = pageNumber
            @_toggleLoadingOverlay()
            @columnModel[i].selectAllFlg = false for i in [0...@columnModel.length] # TODO could be simplyfied
            # TODO lot of work to do here
            new Ajax.Request(@url, {
                parameters: @request,
                onSuccess: (response) ->
                    tableModel = response.responseText.evalJSON()
                    try
                        @rows = tableModel.rows or []
                        @pager = null
                        @pager = tableModel.options.pager if tableModel.options != null and tableModel.options.pager
                        @pager = {} if @pager == null
                        @pager.pageParameter = pageParameter
                        @renderedRows = 0
                        @innerBodyDiv.html(@_createTableBody(tableModel.rows))
                        @bodyTable = $('#mtgBT' + @_mtgId)
                        if tableModel.rows.length > 0 and !firstTimeFlg
                            @_applyCellCallbacks()
                            @keys = new KeyTable(self)
                            @_addKeyBehavior()

                        if (@pager)
                            @pagerDiv.html(@_updatePagerInfo()) # update pager info panel
                            @_addPagerBehavior()

                        @afterRender() if @afterRender
                    catch ex
                        @onFailure(response) if @onFailure
                    finally
                        @_toggleLoadingOverlay()
                        @scrollTop = @bodyDiv.scrollTop = 0
                        @bodyDiv.fire('dom:dataLoaded') if firstTimeFlg
                onFailure : (transport) ->
                    @onFailure(transport) if @onFailure
                    @_toggleLoadingOverlay()
                    @scrollTop = @bodyDiv.scrollTop = 0
                    @bodyDiv.fire('dom:dataLoaded') if firstTimeFlg
            })

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
                if pager.pages
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

            @renderedRowsAllowed = Math.floor(@bodyDiv.clientHeight / @cellHeight)
            if tallerFlg
                html = @_createTableBody(@rows);
                @bodyTable.find('tbody').append(html)
                @_addKeyBehavior()
                @_applyCellCallbacks()
                @keys.addMouseBehavior()

        getValueAt : (x, y) ->
            value = null
            columnId = @columnModel[x].id
            value = if y >= 0 then @rows[y][columnId] else @newRowsAdded[Math.abs(y)-1][columnId]
            return value

        setValueAt : (value, x, y, refreshValueFlg) ->
            cm = @columnModel
            id = @_mtgId
            editor = cm[x].editor
            columnId = cm[x].id

            if refreshValueFlg == undefined or refreshValueFlg
                if editor != null and (editor == 'checkbox' or editor instanceof TableGrid.CellCheckbox or editor == 'radio' or editor instanceof TableGrid.CellRadioButton)
                    input = $('#mtgInput'+id+'_'+x+','+y)
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
                    $('#mtgIC'+id+'_'+x+','+y).html(value)

            if y >= 0
                @rows[y][columnId] = value
            else
                @newRowsAdded[Math.abs(y)-1][columnId] = value

        getColumnIndex : (id) ->
            index = -1
            for i in [0...@columnModel.length]
                if @columnModel[i].id == id
                    index = @columnModel[i].positionIndex
                    break
            return index;

        getIndexOf : (id) ->
            cm = @columnModel
            idx = -1
            for i in[0...cm.length]
                if cm[i].id == id
                    idx = i
                    break
            return idx

        getCurrentPosition : ->
            return [@keys._xCurrentPos, @keys._yCurrentPos]

        getCellElementAt : (x, y) ->
            return $('#mtgC'+@_mtgId + '_' + x + ',' + y)

        getModifiedRows : ->
            result = []
            modifiedRows = @modifiedRows
            rows = @rows
            for i in [0...modifiedRows.length]
                idx = modifiedRows[i]
                result.push(rows[idx])
            return result

        getNewRowsAdded : ->
            return @newRowsAdded

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
                if rowIdx >= 0
                    result.push(rows[rowIdx])
                else
                    result.push(newRowsAdded[Math.abs(rowIdx)-1])
            return result;


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