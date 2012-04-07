require(['jquery','cs!myui/TextField'], function($, TextField) {
    $(document).ready(function(){
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
    });
});
