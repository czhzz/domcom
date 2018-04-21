{task, logTime} = require("gulp-task-helper")

webpack = require('webpack')

{makeConfig, makeWebpackDevServer} = require('../webpack-config')

onTaskDone = -> (err, stats) ->
  if err then console.log('Error', err)
  else console.log(stats.toString())
  logTime("finished 'webpack'")
  return

webpack = require("webpack")
#ClosureCompilerPlugin = require('webpack-closure-compiler')

domcomEntry = {
  'domcom': './src/domcom',
}
runWebPack = (entry, filename, options) ->
  config = makeConfig(entry, filename, options)
  webpackCompiler = webpack(config)
  webpackCompiler.run onTaskDone()

webpackDistribute = (mode) ->
  plugins = [new webpack.NoErrorsPlugin()]
  runWebPack(domcomEntry, '[name].js', {path:'../dist', pathinfo:true, libraryTarget:'umd', library:'dc', plugins})
  runWebPack('./test/mocha/index', 'mocha-index.js', {path:'../dist', pathinfo:true, plugins})
  runWebPack('./demo/index', 'demo-index.js', {path:'../dist', pathinfo:true, plugins})
  runWebPack('./demo/todomvc/todomvc', 'todomvc.js', {path:'../dist', pathinfo:true, plugins})
  if mode=='dist'
    plugins.push new webpack.optimize.UglifyJsPlugin({minimize: true})
    runWebPack(domcomEntry, '[name].min.js', {path:'../dist', pathinfo:false, libraryTarget:'umd', library:'dc', plugins})

task 'webpack-dist', () -> webpackDistribute('dist')
task 'webpack-dev', () -> webpackDistribute('dev')

task 'webpack-server', ->
  webServerPlugins = [
    new webpack.HotModuleReplacementPlugin()
    new webpack.NoErrorsPlugin()
  ]
  makeWebpackDevServer(["webpack/hot/dev-server", './src/domcom'], 'domcom.js', {port:8083, inline:true, plugins:webServerPlugins})
  makeWebpackDevServer(["webpack/hot/dev-server", './test/mocha/index'], 'mocha-index.js', {port:8088, plugins:webServerPlugins})
  makeWebpackDevServer(["webpack/hot/dev-server", './demo/index'], 'demo-index.js', {port:8089, plugins:webServerPlugins})
  makeWebpackDevServer(["webpack/hot/dev-server", './demo/todomvc/todomvc'], 'todomvc.js', {port:8090, plugins:webServerPlugins})
