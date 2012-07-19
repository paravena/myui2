({
    appDir : '.',
    baseUrl : 'scripts',
    dir : 'build',
    stubModules: ['cs'],
    mainConfigFile : 'scripts/main.js',
    modules : [
        {
            name : 'main',
            exclude: ['jquery', 'jquerypp.custom', 'cs']
        }
    ]
})