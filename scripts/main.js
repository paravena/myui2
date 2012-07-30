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
                    editable: true
                },
                {
                    id : 'manufName',
                    title : 'Manufacturer',
                    width : 140,
                    editable: true
                },
                {
                    id : 'manufDesc',
                    title : 'Description',
                    width : 90,
                    editable: true
                }
            ],
            //url : 'get_all_manufacturers.php'
            rows : [
                {'manufId': '1', 'manufName': 'Toyota', 'manufDesc' : 'Japanese Manufacturer'},
                {'manufId': '2', 'manufName': 'Honda', 'manufDesc' : 'Japanese Manufacturer'},
                {'manufId': '3', 'manufName': 'Daihatsu', 'manufDesc' : 'Japanese Manufacturer'},
                {'manufId': '4', 'manufName': 'Nissan', 'manufDesc' : 'Japanese Manufacturer'},
                {'manufId': '5', 'manufName': 'Mitsubishi', 'manufDesc' : 'Japanese Manufacturer'},
                {'manufId': '6', 'manufName': 'Renault', 'manufDesc' : 'French Manufacturer'},
                {'manufId': '7', 'manufName': 'Peugeot', 'manufDesc' : 'French Manufacturer'},
                {'manufId': '8', 'manufName': 'Citroen', 'manufDesc' : 'French Manufacturer'},
                {'manufId': '9', 'manufName': 'Simca', 'manufDesc' : 'French Manufacturer'},
                {'manufId': '10', 'manufName': 'BMW', 'manufDesc' : 'German Manufacturer'},
                {'manufId': '11', 'manufName': 'Audi', 'manufDesc' : 'German Manufacturer'},
                {'manufId': '12', 'manufName': 'Volkswagen', 'manufDesc' : 'German Manufacturer'},
                {'manufId': '13', 'manufName': 'Mercedes Benz', 'manufDesc' : 'German Manufacturer'},
                {'manufId': '14', 'manufName': 'KIA', 'manufDesc' : 'Korean Manufacturer'},
                {'manufId': '15', 'manufName': 'Hyundai', 'manufDesc' : 'Korean Manufacturer'},
                {'manufId': '16', 'manufName': 'Samsung', 'manufDesc' : 'Korean Manufacturer'}
            ]
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
