require(['cs!myui/ComboBox'], function(ComboBox) {
    $(document).ready(function(){
        new ComboBox({
            input : '#name',
            url : 'get_manufacturers_list.php',
            indicator : 'ai',
            required : true,
            initialText : 'Enter a manufacturer'
        });
    });
});
