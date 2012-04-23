require(['jquery', 'cs!myui/TextField', 'cs!myui/Autocompleter', 'cs!myui/ComboBox'], function($, TextField, Autocompleter, ComboBox) {
    $(document).ready(function(){
        /*
        new TextField({input: '#name',
            initialText: 'Enter name',
            required: true,
            validate : function(value, errors) {
                var result = true;
                if (value != 'peter') {
                    errors.push('bad name');
                    result = false;
                }
                return result;
            }
        });
        */
        window.comboBox = new ComboBox({
            input : '#name',
            url : 'get_manufacturers_list.php',
            indicator : 'ai',
            required : true,
            initialText : 'Enter a manufacturer'
        });
    });
});
