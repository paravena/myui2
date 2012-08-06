require(['cs!myui/ComboBox', 'cs!myui/TableGrid'], function(ComboBox, TableGrid) {
    $(document).ready(function() {
        var countryList = [
            {value: 'FR', text: 'France'},
            {value: 'UK', text: 'United Kingdon'},
            {value: 'US', text: 'United States'},
            {value: 'CL', text: 'Chile'},
            {value: 'BR', text: 'Brazil'},
            {value: 'IT', text: 'Italy'},
            {value: 'DE', text: 'Germany'},
            {value: 'KR', text: 'Korea'},
            {value: 'JP', text: 'Japan'}
        ];

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
                    editable : true
                },
                {
                    id : 'origCountry',
                    title : 'Origin Country',
                    width : 100,
                    editable: true,
                    editor: new ComboBox({
                        items: countryList
                    })
                }
            ],
            //url : 'get_all_manufacturers.php'
            rows : [
                {'manufId': '1', 'manufName': 'Toyota', 'manufDesc' : 'Japanese Manufacturer', 'origCountry' : 'JP'},
                {'manufId': '2', 'manufName': 'Honda', 'manufDesc' : 'Japanese Manufacturer', 'origCountry' : 'JP'},
                {'manufId': '3', 'manufName': 'Daihatsu', 'manufDesc' : 'Japanese Manufacturer', 'origCountry' : 'JP'},
                {'manufId': '4', 'manufName': 'Nissan', 'manufDesc' : 'Japanese Manufacturer', 'origCountry' : 'JP'},
                {'manufId': '5', 'manufName': 'Mitsubishi', 'manufDesc' : 'Japanese Manufacturer', 'origCountry' : 'JP'},
                {'manufId': '6', 'manufName': 'Renault', 'manufDesc' : 'French Manufacturer', 'origCountry' : 'JP'},
                {'manufId': '7', 'manufName': 'Peugeot', 'manufDesc' : 'French Manufacturer', 'origCountry' : 'FR'},
                {'manufId': '8', 'manufName': 'Citroen', 'manufDesc' : 'French Manufacturer', 'origCountry' : 'FR'},
                {'manufId': '9', 'manufName': 'Simca', 'manufDesc' : 'French Manufacturer', 'origCountry' : 'FR'},
                {'manufId': '10', 'manufName': 'BMW', 'manufDesc' : 'German Manufacturer', 'origCountry' : 'DE'},
                {'manufId': '11', 'manufName': 'Audi', 'manufDesc' : 'German Manufacturer', 'origCountry' : 'DE'},
                {'manufId': '12', 'manufName': 'Volkswagen', 'manufDesc' : 'German Manufacturer', 'origCountry' : 'DE'},
                {'manufId': '13', 'manufName': 'Mercedes Benz', 'manufDesc' : 'German Manufacturer', 'origCountry' : 'DE'},
                {'manufId': '14', 'manufName': 'KIA', 'manufDesc' : 'Korean Manufacturer', 'origCountry' : 'KR'},
                {'manufId': '15', 'manufName': 'Hyundai', 'manufDesc' : 'Korean Manufacturer', 'origCountry' : 'KR'},
                {'manufId': '16', 'manufName': 'Samsung', 'manufDesc' : 'Korean Manufacturer', 'origCountry' : 'KR'}
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
