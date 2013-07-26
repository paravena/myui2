
require.config({
    baseUrl : '../../scripts',
    shim : {
        'jquery' : ['myui', 'jquerypp.custom']
    },
    paths : {
        'jquery' : 'libs/jquery',
        'jquerypp.custom' : 'libs/jquerypp.custom'
    }
});

define([
    'jquery',
    'jquerypp.custom',
    'cs!myui/TextField',
    'cs!myui/Autocompleter',
    'cs!myui/ComboBox',
    'cs!myui/DatePicker',
    'cs!myui/Checkbox',
    'cs!myui/RadioButton',
    'cs!myui/TableGrid'], function($,
                                   jquerypp,
                                   TextField,
                                   Autocompleter,
                                   ComboBox,
                                   DatePicker,
                                   Checkbox,
                                   RadioButton,
                                   TableGrid) {
        window.MY = {};
        MY.TextField = TextField;
        MY.Autocompleter = Autocompleter;
        MY.ComboBox = ComboBox;
        MY.DatePicker = DatePicker;
        MY.Checkbox = Checkbox;
        MY.RadioButton = RadioButton;
        MY.TableGrid = TableGrid;
});
