define(function() {
    var i18n = {};
    i18n['EN'] = {};
    i18n['EN']['label.ok'] = 'OK';
    i18n['EN']['label.now'] = 'Now';
    i18n['EN']['label.today'] = 'Today';
    i18n['EN']['label.week'] = 'Week';
    i18n['EN']['label.clear'] = 'Clear';
    i18n['EN']['label.add'] = 'Add';
    i18n['EN']['label.delete'] = 'Delete';
    i18n['EN']['label.save'] = 'Save';
    i18n['EN']['label.sortAsc'] = 'Sort ascending';
    i18n['EN']['label.sortDesc'] = 'Sort descending';
    i18n['EN']['label.selectAll'] = 'Select all';
    i18n['EN']['label.loading'] = 'Loading ...';
    i18n['EN']['label.actions'] = 'Actions';
    i18n['EN']['message.totalDisplay'] = '<strong><span id="mtgTotal">#{total}</span></strong> records found';
    i18n['EN']['message.rowsDisplay'] = ', displaying <strong><span id="mtgFrom">#{from}</span></strong>&nbsp;to&nbsp;<strong><span id="mtgTo">#{to}</span></strong>';
    i18n['EN']['message.pagePrompt'] = '<td><strong>Page:</strong></td><td>#{input}</td><td>of&nbsp;<strong>#{pages}</strong></td>';
    i18n['EN']['message.noRecordFound'] = '<strong>No records found</strong>';
    i18n['EN']['error.required.field'] = '#{field} is required';
    i18n['EN']['error.invalid.creditCard'] = 'value #{value} is not a valid credit card number';
    i18n['EN']['error.invalid.range'] = 'value #{value} does not fall within the valid range from #{from} to #{to}';
    i18n['EN']['error.invalid.size'] = 'value #{value} does not fall within the valid size range from #{from} to #{to}';
    i18n['EN']['error.invalid.max'] = 'value #{value} exceeds maximum value #{max}';
    i18n['EN']['error.invalid.min'] = 'value #{value} is less than minimum value #{min}';
    i18n['EN']['error.invalid.max.size'] = 'value #{value} exceeds the maximum size of #{max}';
    i18n['EN']['error.invalid.min.size'] = 'value #{value} is less than the minimum size of #{min}';
    i18n['EN']['date.monthAbbreviations'] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    i18n['EN']['date.monthNames'] = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    i18n['EN']['date.dayNames'] = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    i18n['EN']['date.dayAbbreviations'] = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    i18n['EN']['date.weekDays'] = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    i18n['ES'] = {};
    i18n['ES']['label.ok'] = 'OK';
    i18n['ES']['label.now'] = 'Ahora';
    i18n['ES']['label.today'] = 'Hoy';
    i18n['ES']['label.week'] = 'Sem';
    i18n['ES']['label.clear'] = 'Limpiar';
    i18n['ES']['label.add'] = 'Agregar';
    i18n['ES']['label.delete'] = 'Eliminar';
    i18n['ES']['label.save'] = 'Grabar';
    i18n['ES']['label.sortAsc'] = 'Ordenar asc';
    i18n['ES']['label.sortDesc'] = 'Ordenar desc';
    i18n['ES']['label.selectAll'] = 'Seleccionar todo';
    i18n['ES']['label.loading'] = 'Espere ...';
    i18n['ES']['label.actions'] = 'Acciones';
    i18n['ES']['message.totalDisplay'] = '<strong><span id="mtgTotal">#{total}</span></strong> filas encontradas';
    i18n['ES']['message.rowsDisplay'] = ', mostrando <strong><span id="mtgFrom">#{from}</span></strong>&nbsp;a&nbsp;<strong><span id="mtgTo">#{to}</span></strong>';
    i18n['ES']['message.pagePrompt'] = '<td><strong>P&aacute;gina:</strong></td><td>#{input}</td><td>de&nbsp;<strong>#{pages}</strong></td>';
    i18n['ES']['message.noRecordFound'] = '<strong>No hay filas</strong>';
    i18n['ES']['error.required.field'] = '#{field} debe ser ingresado';
    i18n['ES']['error.invalid.creditCard'] = 'valor #{value} no es un numero de targeta valido';
    i18n['ES']['error.invalid.range'] = 'valor #{value} esta fuera del rango desde #{from} hasta #{to}';
    i18n['ES']['error.invalid.size'] = 'valor #{value} no es un tamano valido entre #{from} a #{to}';
    i18n['ES']['error.invalid.max'] = 'valor #{value} excede el maximo valor #{max}';
    i18n['ES']['error.invalid.min'] = 'valor #{value} es menos que el minimo permitido #{min}';
    i18n['ES']['error.invalid.max.size'] = 'valor #{value} excede el maximo tamano de #{max}';
    i18n['ES']['error.invalid.min.size'] = 'valor #{value} es menos que el minimo tamano de #{min}';
    i18n['ES']['date.monthAbbreviations'] = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    i18n['ES']['date.monthNames'] = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    i18n['ES']['date.dayNames'] = ['Domingo', 'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'S&aacute;bado'];
    i18n['ES']['date.dayAbbreviations'] = ['Dom', 'Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'S&aacute;b'];
    i18n['ES']['date.weekDays'] = ['Do', 'Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'S&aacute;'];

    i18n['PT'] = {};
    i18n['PT']['label.ok'] = 'OK';
    i18n['PT']['label.now'] = 'Agora';
    i18n['PT']['label.today'] = 'Hoje';
    i18n['PT']['label.week'] = 'Sem';
    i18n['PT']['label.clear'] = 'Limpar';
    i18n['PT']['label.add'] = 'Adicionar';
    i18n['PT']['label.delete'] = 'Excluir';
    i18n['PT']['label.save'] = 'Salvar';
    i18n['PT']['label.sortAsc'] = 'Ordem asc';
    i18n['PT']['label.sortDesc'] = 'Ordem desc';
    i18n['PT']['label.selectAll'] = 'Selecionar tudo';
    i18n['PT']['label.loading'] = 'Aguarde ...';
    i18n['PT']['label.actions'] = 'A&ccedil;&otilde;es';
    i18n['PT']['message.totalDisplay'] = '<strong><span id="mtgTotal">#{total}</span></strong> registros encontrados';
    i18n['PT']['message.rowsDisplay'] = ', mostrando <strong><span id="mtgFrom">#{from}</span></strong>&nbsp;at&eacute;&nbsp;<strong><span id="mtgTo">#{to}</span></strong>';
    i18n['PT']['message.pagePrompt'] = '<td><strong>P&aacute;gina:</strong></td><td>#{input}</td><td>de&nbsp;<strong>#{pages}</strong></td>';
    i18n['PT']['message.noRecordFound'] = '<strong>Sem registros</strong>';
    i18n['PT']['error.required.field'] = '#{field} &eacute; obrigat&oacute;rio';
    i18n['PT']['error.invalid.creditCard'] = 'valor #{value} n&atilde;o &eacute; um n&uacute;mero de cart&atilde;o v&aacute;lido';
    i18n['PT']['error.invalid.range'] = 'valor #{value} est&aacute; fora do intervalo de #{from} at&eacute; #{to}';
    i18n['PT']['error.invalid.size'] = 'valor #{value} n&atilde;o &eacute; um tamanho v&aacute;lido entre #{from} e #{to}';
    i18n['PT']['error.invalid.max'] = 'valor #{value} excede o m&aacute;ximo valor #{max}';
    i18n['PT']['error.invalid.min'] = 'valor #{value} &eacute; menor que o m&iacute;nimo permitido #{min}';
    i18n['PT']['error.invalid.max.size'] = 'valor #{value} excede o m&aacute;ximo tamanho de #{max}';
    i18n['PT']['error.invalid.min.size'] = 'valor #{value} &eacute; menor que o m&iacute;nimo tamanho de #{min}';
    i18n['PT']['date.monthAbbreviations'] = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    i18n['PT']['date.monthNames'] = ['Janeiro', 'Fevereiro', 'Mar&ccedil;o', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];
    i18n['PT']['date.dayNames'] = ['Domingo', 'Segunda', 'Ter&ccedil;a', 'Quarta', 'Quinta', 'Sexta', 'S&aacute;bado'];
    i18n['PT']['date.dayAbbreviations'] = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'S&aacute;b'];
    i18n['PT']['date.weekDays'] = ['Do', 'Se', 'Te', 'Qua', 'Qui', 'Sex', 'S&aacute;'];

    i18n.getMessage = function(messageId, options) {
        options = options || {};
        var result = messageId;
        var language = window.navigator.userLanguage || window.navigator.language;
        var languageCd = language.substring(0,2).toUpperCase();
        try {
            var messages = this[languageCd] || this['EN'];
            if (messages[messageId]) {
                var temp = messages[messageId];
                for (p in options) {
                    var re = new RegExp('#\{'+p+'\}','g');
                    temp = temp.replace(re, options[p]);
                }
                return temp;
            }
        } catch(e) {
            result = messageId;
        }
        return result;
    };
    return i18n;
});