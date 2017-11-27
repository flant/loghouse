'use strict';

var path = require('path');
var gulp = require('gulp');
var gutil = require('gulp-util');
var browserify = require('browserify');
var source = require('vinyl-source-stream');
var buffer = require('vinyl-buffer');
var uglify = require('gulp-uglify');
var minifyCSS = require('gulp-minify-css');
var sourcemaps = require('gulp-sourcemaps');

var conf = require('./conf');

var $ = require('gulp-load-plugins')({
    pattern: ['gulp-*', 'uglify-save-license', 'del']
});


gulp.task('other', function () {
    var fileFilter = $.filter(function (file) {
        return file.stat.isFile();
    });

    return gulp.src([
        path.join(conf.paths.src, '/**/*'),
        path.join('!' + conf.paths.src, '/**/*.{html,css,js,less,json}')
    ])
        .pipe(fileFilter)
        .pipe(gulp.dest(path.join(conf.paths.dist, '/')));
});

gulp.task('fonts', function () {
    var fileFilter = $.filter(function (file) {
        return file.stat.isFile();
    });

    return gulp.src([
        path.join(conf.paths.nodeModules, 'bootstrap3/dist/fonts/*'),
    ])
        .pipe(fileFilter)
        .pipe(gulp.dest(path.join(conf.paths.dist, '/fonts')));
});

gulp.task('clean', function () {
    return $.del([path.join(conf.paths.dist, '/'), path.join(conf.paths.tmp, '/')]);
});

gulp.task('prebuild', ['fonts', 'other']);

gulp.task('js', ['prebuild'], function() {
    var b = browserify({
        entries: path.join(conf.paths.src, 'js/app.js'),
        debug: true
    });

    return b.bundle()
        .pipe(source('app.js'))
        .pipe(buffer())
        .pipe(sourcemaps.init({loadMaps: true}))
        .pipe(conf.production ? uglify() : gutil.noop())
        .on('error', conf.errorHandler('js'))
        .pipe(sourcemaps.write('./'))
        .pipe(gulp.dest(path.join(conf.paths.dist, '/js')));
});

gulp.task('css', ['prebuild'], function() {
    return gulp
        .src([
            path.join(conf.paths.nodeModules, 'bootstrap3/dist/css/bootstrap.css'),
            path.join(conf.paths.nodeModules, 'eonasdan-bootstrap-datetimepicker/build/css/bootstrap-datetimepicker.css'),
            path.join(conf.paths.nodeModules, 'select2/dist/css/select2.css'),
            path.join(conf.paths.nodeModules, 'select2-bootstrap-theme/dist/select2-bootstrap.css'),
            path.join(conf.paths.src, '**/*.css'),
        ])
        .pipe($.concat('app.css'))
        .pipe(conf.production ? minifyCSS() : gutil.noop())
        .on('error', conf.errorHandler('css'))
        .pipe(gulp.dest(path.join(conf.paths.dist, '/css')));
});

gulp.task('watch', ['default'], function() {
        gulp.watch(path.join(conf.paths.src, '**/*.css'), function(event) {
            console.log('File ' + event.path + ' was ' + event.type + ', running tasks...');
            gulp.start('css');
        });

        gulp.watch(path.join(conf.paths.src, '**/*.js'), function(event) {
            console.log('File ' + event.path + ' was ' + event.type + ', running tasks...');
            gulp.start('js');
        });

        gulp.watch(path.join('!' + conf.paths.src, '/**/*.{html,css,js,less,json}'), function(event) {
            console.log('File ' + event.path + ' was ' + event.type + ', running tasks...');
            gulp.start('other');
        });
});

gulp.task('build', ['js', 'css']);
