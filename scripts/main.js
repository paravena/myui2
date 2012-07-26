require(['cs!myui/TableGrid'], function(TableGrid) {
    $(document).ready(function(){
        var tableModel = {
            options : {
                width: '640px',
                title: 'Manufacturers',
                toolbar : {
                    elements: [TableGrid.ADD_BTN, TableGrid.DEL_BTN, TableGrid.SAVE_BTN],
                    onSave: function() {
                        var newRowsAdded = tableGrid1.getNewRowsAdded();
                        var temp = '';
                        for (var i = 0; i < newRowsAdded.length; i++) {
                            temp += '{';
                            for (var p in newRowsAdded[i]) {
                                temp += p + ' : ' + newRowsAdded[i][p] + ', ';
                            }
                            temp += '}\n';
                        }
                        alert('added rows: ' + temp);
                        var modifiedRows = tableGrid1.getModifiedRows();
                        temp = '';
                        for (var i = 0; i < modifiedRows.length; i++) {
                            temp += '{';
                            for (var p in modifiedRows[i]) {
                                temp += p + ' : ' + modifiedRows[i][p] + ', ';
                            }
                            temp += '}\n';
                        }
                        alert('modified rows: ' + temp);
                        var deletedRows = tableGrid1.getDeletedRows();
                        temp = '';
                        for (var i = 0; i < deletedRows.length; i++) {
                            temp += '{';
                            for (var p in deletedRows[i]) {
                                temp += p + ' : ' + deletedRows[i][p] + ', ';
                            }
                            temp += '}\n';
                        }
                        alert('deleted rows: ' + temp);
                    },
                    onAdd: function() {
                        //alert('on add handler');
                    },
                    onDelete: function() {
                        //alert('on delete handler');
                    }
                },
                rowClass : function(rowIdx) {
                    var className = '';
                    if (rowIdx % 2 == 0) {
                        className = 'hightlight';
                    }
                    return className;
                }
            },
            columnModel : [
                {
                    id : 'manufId',
                    title : 'Id',
                    width : 30,
                    editable: true,
                    editor: new TableGrid.CellCheckbox({
                        selectable : true,
                        onClick : function(value, checked) {
                            alert(value + ' ' + checked);
                        }
                    })
                },
                {
                    id : 'manufName',
                    title : 'Manufacturer',
                    width : 140,
                    editable: true,
                    sortable: true
                },
                {
                    id : 'manufDesc',
                    title : 'Description',
                    width : 90,
                    editable: true,
                    sortable: true
                }
            ],
            url : 'get_all_manufacturers.php'
        };

        var tableGrid1 = new TableGrid(tableModel);
        tableGrid1.render('#mytable1');
    /*
        new ComboBox({
            input : '#name',
            url : 'get_manufacturers_list.php',
            indicator : 'ai',
            required : true,
            initialText : 'Enter a manufacturer'
        });
    */
    });

});
