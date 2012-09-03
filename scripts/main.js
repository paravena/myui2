/*
requirejs.config({
   baseUrl : '../../scripts',
   paths : {
       'jquery' : 'libs/jquery',
       'jquerypp.custom' : 'libs/jquerypp.custom'
   }
});
*/
require([
    'cs!myui/TextField',
    'cs!myui/Autocompleter',
    'cs!myui/ComboBox',
    'cs!myui/DatePicker',
    'cs!myui/TableGrid'], function(TextField,
                                   Autocompleter,
                                   ComboBox,
                                   DatePicker,
                                   TableGrid) {
        window.MY = {};
        MY.TextField = TextField;
        MY.Autocompleter = Autocompleter;
        MY.ComboBox = ComboBox;
        MY.DatePicker = DatePicker;
        MY.TableGrid = TableGrid;
});
