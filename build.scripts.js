({
    baseUrl : 'assets',
    stubModules: ['cs'],
    name : 'myui',
    optimize : 'none',
    out : 'assets/myui.min.js',
    paths : {
        'requireLib' : 'js/libs/requirejs/require',
        'cs' : 'js/libs/requirejs/cs',
        'i18n' : 'js/libs/requirejs/i18n',
        'jquery' : 'js/libs/jquery/jquery',
        'jquerypp.custom' : 'js/libs/jquery/jquerypp.custom'
    },
    /*exclude : ['jquery', 'jquerypp.custom'],*/
    include : ['requireLib']
})