
require.config({
    baseUrl : '/carcenter-web/assets',
    shim : {
        'jquery' : ['myui', 'jquerypp.custom']
    },
    paths : {
        'jquery' : 'js/libs/jquery/jquery',
        'jquerypp.custom' : 'js/libs/jquery/jquerypp.custom'
    }
});

define([
    'jquery',
    'jquerypp.custom',
    'cs!js/myui/TextField',
    'cs!js/myui/ToolTip',
    'cs!js/myui/Autocompleter',
    'cs!js/myui/ComboBox',
    'cs!js/myui/DatePicker',
    'cs!js/myui/Checkbox',
    'cs!js/myui/RadioButton',
    'cs!js/myui/TableGrid'], function($,
                                   jquerypp,
                                   TextField,
                                   ToolTip,
                                   Autocompleter,
                                   ComboBox,
                                   DatePicker,
                                   Checkbox,
                                   RadioButton,
                                   TableGrid) {
        window.MY = {};
        MY.TextField = TextField;
        MY.ToolTip = ToolTip;
        MY.Autocompleter = Autocompleter;
        MY.ComboBox = ComboBox;
        MY.DatePicker = DatePicker;
        MY.Checkbox = Checkbox;
        MY.RadioButton = RadioButton;
        MY.TableGrid = TableGrid;
});
