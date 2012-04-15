require(['jquery','cs!myui/Autocompleter'], function($, Autocompleter) {
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
        new Autocompleter({
            input : '#name',
            url : 'get_manufacturers_list.php',
            indicator : 'ai',
            required : true,
            initialText : 'Enter a manufacturer'
        });
    });
});
