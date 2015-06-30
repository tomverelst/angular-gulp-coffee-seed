gulp            = require 'gulp'
coffee          = require 'gulp-coffee'
autoprefixer    = require 'gulp-autoprefixer'
minifycss       = require 'gulp-minify-css'
sass            = require 'gulp-ruby-sass'
gutil           = require 'gulp-util'
stripDebug      = require 'gulp-strip-debug'
uglify          = require 'gulp-uglify'
shell           = require 'gulp-shell'
exec            = require 'sync-exec'
rename          = require 'gulp-rename'
concat          = require 'gulp-concat'
runSequence     = require 'run-sequence'
del             = require 'del'

APP_ROOT = exec("pwd").stdout.trim() + "/"

# Used in "development" environment as a IP for the server.
# You can specify it by using LOCAL_IP env variable in your cli commands.
LOCAL_IP = process.env.LOCAL_IP || exec("(ifconfig wlan 2>/dev/null || ifconfig en0) | grep inet | grep -v inet6 | awk '{print $2}' | sed 's/addr://g'").stdout.trim()
LOCAL_IP = "127.0.0.1" unless parseInt(LOCAL_IP) > 0

ENV_GLOBALS =
  development:
    ENV: "development"
    BUILD_DIR: 'target'
  production:
    ENV: "production"

GLOBALS = require('extend') true, {}, ENV_GLOBALS.development, (ENV_GLOBALS[gutil.env.env] || {})

# You can replace any of GLOBALS by defining ENV variable in your command line,
# f.e. `FOO="bar" gulp`
for k, v of GLOBALS
  GLOBALS[k] = process.env[k] if process.env[k]? && GLOBALS[k]?

#SRC_INDEX_HTML =            "#{STAGE_APP_DIR}/index/index.html"
#DEST_INDEX_HTML =           "#{BUILD_MAIN_DIR}/index.html"

paths =
  src: './src/main/**/*.coffee'
  assets: ['assets/**']
  styles: ['src/main/**/*.scss']

destinations =
  src: "#{GLOBALS.BUILD_DIR}/"
  assets: "#{GLOBALS.BUILD_DIR}/assets"
  styles: "#{GLOBALS.BUILD_DIR}/css"

gulp.task 'bower:install', shell.task('bower install')

gulp.task 'express', ->
  express = require 'express'
  app = express()
  app.use express.static "#{BUILD_MAIN_DIR}"
  app.listen 4000

gulp.task 'assets', ->
  gulp.src paths.assets

gulp.task 'styles', ->
  sass 'src/main/', style: 'expanded'
  .pipe autoprefixer 'last 2 versions', 'safari 5', 'ie 8', 'ie 9', 'opera 12.1'
  .pipe rename suffix: '.min'
  .pipe gulp.dest ('css')

gulp.task 'clean', ->
  del GLOBALS.BUILD_DIR, (err, paths) ->
    console.log err if err?
    console.log 'Cleaned build dir:\n', paths.join '\n' unless err?

gulp.task 'compile', ['compile:coffee']

#
# Compile Coffee scripts to JavaScript
#
gulp.task 'compile:coffee', ->
  gulp.src paths.src
  .pipe coffee bare: true
  .on "error", gutil.log
  .pipe concat 'app.js'
  .pipe stripDebug()
  .pipe uglify()
  .pipe rename extname: '.min.js'
  .pipe gulp.dest destinations.src

gulp.task 'watch', ->
  gulp.watch 'src/main/*.scss', ['styles']

gulp.task 'build', (callback) ->
  runSequence ["clean", "bower:install"],
    [
      "assets"
      "styles"
      "compile"
    ], callback


gulp.task 'default', (callback) ->
  runSequence "build", ["watch", "express"], callback ->