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
                    @columnModel[i].editable = true if @columnModel[i].editor == 'checkbox' or @columnModel[i].editor instanceof CellCheckbox or @columnModel[i].editor == 'radio' or @columnModel[i].editor instanceof CellRadioButton
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
          
            self = this
          
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
                        if elements[i].hasOwnProperty('children') && elements[i].children.length > 0
                            children = elements[i].children
                            result[idx++] = children[j] for j in [0...children.length]
                else
                    if column.hasOwnProperty('children') && column.children.length > 0
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