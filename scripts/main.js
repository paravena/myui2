require(['cs!myui/ComboBox'], function(ComboBox) {
    $(document).ready(function(){
        window.comboBox = new ComboBox({
            input : '#name',
            url : 'get_manufacturers_list.php',
            indicator : 'ai',
            required : true,
            initialText : 'Enter a manufacturer'
        });
    });
});
