({
    baseUrl : 'scripts',
    stubModules: ['cs'],
    name : 'main',
    //optimize : 'none',
    out : 'scripts/myui.min.js',
    paths : {
        'requireLib' : 'libs/require',
        'cs' : 'libs/cs',
        'i18n' : 'libs/i18n',
        'jquery' : 'libs/jquery',
        'jquerypp.custom' : 'libs/jquerypp.custom'
    },
    //exclude : ['jquery', 'jquerypp.custom'],
    include : ['requireLib']
})
