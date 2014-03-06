module.exports = ->
  # Project configuration
  @initConfig
    pkg: @file.readJSON 'package.json'

    # CoffeeScript compilation
    coffee:
      spec:
        options:
          bare: true
        expand: true
        cwd: 'spec'
        src: ['**.coffee']
        dest: 'spec'
        ext: '.js'

    # Directory cleaning
    clean:
      build: [
        'browser'
        'preview/browser'
      ]
      dependencies: [
        'bower_components'
        'components/*/'
        'preview/components'
      ]
      dist: [
        'dist'
      ]

    # Browser version building
    exec:
      bower_install:
        command: 'node ./node_modules/bower/bin/bower install'
      main_install:
        command: 'node ./node_modules/component/bin/component install'
      main_build:
        command: 'node ./node_modules/component/bin/component build -u component-json,component-coffee -o browser -n noflo-ui -c'
      preview_install:
        command: 'node ./node_modules/component/bin/component install'
        cwd: 'preview'
      preview_build:
        command: 'node ./node_modules/component/bin/component build -u component-json,component-coffee -o browser -n noflo-ui-preview -c'
        cwd: 'preview'
      vulcanize:
        command: 'node ./node_modules/vulcanize/bin/vulcanize --csp -o app.html index.html'

    # JavaScript minification for the browser
    uglify:
      options:
        report: 'min'
      noflo:
        files:
          './browser/noflo-ui.min.js': ['./browser/noflo-ui.js']
      preview:
        files:
          './preview/browser/noflo-ui-preview.min.js': ['./preview/browser/noflo-ui-preview.js']

    'string-replace':
      app:
        files:
          './app.html': './app.html'
          './app.js': './app.js'
          './manifest.json': './manifest.dist.json'
        options:
          replacements: [
            pattern: /\$NOFLO_OAUTH_CLIENT_ID/ig
            replacement: process.env.NOFLO_OAUTH_CLIENT_ID or '9d963a3d-8b6f-42fe-bb36-6fccecd039af'
          ,
            pattern: /\$NOFLO_APP_TITLE/ig
            replacement: process.env.NOFLO_APP_TITLE or 'NoFlo Development Environment'
          ,
            pattern: /\$NOFLO_APP_VERSION/ig
            replacement: '<%= pkg.version %>'
          ,
            pattern: /\$NOFLO_THEME/ig
            replacement: process.env.NOFLO_THEME or 'noflo'
          ]

    compress:
      app:
        options:
          archive: 'noflo-<%= pkg.version %>.zip'
        files: [
          src: ['browser/noflo-noflo-indexeddb/vendor/*']
          expand: true
          dest: '/'
        ,
          src: ['browser/noflo-noflo-polymer/noflo-polymer/*']
          expand: true
          dest: '/'
        ,
          src: ['browser/noflo-ui.js']
          expand: true
          dest: '/'
        ,
          src: [
            'bower_components/**/*.js'
            'bower_components/**/*.css'
            'bower_components/**/*.woff'
            'bower_components/**/*.ttf'
            'bower_components/**/*.svg'
          ]
          expand: true
          dest: '/'
        ,
          src: ['app.js']
          expand: true
          dest: '/'
        ,
          src: ['app.html']
          expand: true
          dest: '/'
          rename: (dest, src) -> 'index.html'
        ,
          src: ['app/*']
          expand: true
          dest: '/'
        ,
          src: ['manifest.json']
          expand: true
          dest: '/'
        ,
          src: ['config.xml']
          expand: true
          dest: '/'
        ,
          src: ['css/*']
          expand: true
          dest: '/'
        ,
          src: ['preview/browser/noflo-noflo-runtime-iframe/runtime/network.js']
          expand: true
          dest: '/'
        ,
          src: ['preview/browser/noflo-ui-preview.js']
          expand: true
          dest: '/'
        ,
          src: ['preview/iframe.html']
          expand: true
          dest: '/'
        ]

    "phonegap-build":
      app:
        options:
          archive: 'noflo-<%= pkg.version %>.zip'
          appId: process.env.PHONEGAP_APP_ID
          user:
            token: process.env.PHONEGAP_TOKEN

    unzip:
      dist: 'noflo-<%= pkg.version %>.zip'

    'gh-pages':
      options:
        base: 'dist'
        clone: 'gh-pages'
        message: 'Updating web version to <%= pkg.version %>'
      src: '**/*'


    # Coding standards
    coffeelint:
      # noflo:
      options:
        max_line_length:
          level: "ignore"
      files: [
        'Gruntfile.coffee'
        'src/*.coffee'
        'src/**/*.coffee'
        'components/*.coffee'
        'spec/*.coffee'
      ]

    inlinelint:
      options:
        strict: false,
        newcap: false,
        "globals": { "Polymer": true }
      all:
        src: ['elements/*.html']


  # Grunt plugins used for building
  @loadNpmTasks 'grunt-contrib-coffee'
  @loadNpmTasks 'grunt-exec'
  @loadNpmTasks 'grunt-contrib-uglify'
  @loadNpmTasks 'grunt-contrib-clean'
  @loadNpmTasks 'grunt-string-replace'

  # Grunt plugins used for mobile app building
  @loadNpmTasks 'grunt-contrib-compress'
  @loadNpmTasks 'grunt-zip'
  @loadNpmTasks 'grunt-gh-pages'
  @loadNpmTasks 'grunt-phonegap-build'

  # Grunt plugins used for testing
  @loadNpmTasks 'grunt-contrib-watch'
  #@loadNpmTasks 'grunt-mocha-phantomjs'
  @loadNpmTasks 'grunt-coffeelint'
  @loadNpmTasks 'grunt-lint-inline'

  # Our local tasks
  @registerTask 'nuke', ['clean']
  @registerTask 'build', ['inlinelint', 'exec:main_install', 'exec:bower_install', 'exec:main_build', 'exec:preview_install', 'exec:preview_build', 'exec:vulcanize', 'string-replace', 'compress']
  @registerTask 'main_build', ['exec:main_install', 'exec:bower_install', 'exec:main_build']
  @registerTask 'main_rebuild', ['clean:nuke_main', 'clean:nuke_bower', 'main_build']
  @registerTask 'preview_build', ['exec:preview_install', 'exec:preview_build']
  @registerTask 'preview_rebuild', ['clean:nuke_preview', 'preview_build']
  @registerTask 'rebuild', ['main_rebuild', 'preview_rebuild']
  @registerTask 'test', ['coffeelint', 'inlinelint']
  @registerTask 'app', ['build', 'phonegap-build']
  @registerTask 'default', ['test']
  @registerTask 'pages', ['build', 'clean:dist', 'unzip', 'gh-pages']
