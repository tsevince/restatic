ansi = require("ansi")
cursor = ansi(process.stdout)
rimraf = require("rimraf")
wrench = require("wrench")
fs = require("fs")
path = require("path")
Environment = ->

Environment.conf = {}
Environment::prepare = (lineArgs, configFile) ->
  defaultExtractor = "GoogleSpreadsheetDataExtractor"
  @loadLineArgs lineArgs
  @loadConfigFile configFile
  @loadExtractor defaultExtractor
  @prepareEnvironment()
  if @checkResults()
    Environment.conf
  else
    false

Environment::loadExtractor = (defaultExtractor) ->
  extractor = Environment.conf.extractor
  nativeExtractor = __dirname + "/extractors/" + extractor + ".js"
  defaultExtractorFullPath = __dirname + "/extractors/" + defaultExtractor + ".js"
  unless path.existsSync(extractor)
    unless path.existsSync(nativeExtractor)
      extractor = defaultExtractorFullPath
      Environment.conf.extractorName = defaultExtractor
    else
      Environment.conf.extractorName = extractor
      extractor = nativeExtractor
  Environment.conf.extractor = extractor

Environment::prepareEnvironment = ->
  if (Environment.conf.mode isnt "fetch") and (typeof Environment.conf.source isnt "undefined") or (typeof Environment.conf.target isnt "undefined")
    if Environment.conf.target is "./_site/"
      dirName = "/tmp/restatic_temp/"
      fs.mkdirSync dirName, 0o777
      wrench.copyDirSyncRecursive Environment.conf.source, dirName
      rimraf.sync Environment.conf.target
      fs.mkdirSync Environment.conf.target, 0o777
      wrench.copyDirSyncRecursive dirName, Environment.conf.target
      rimraf.sync dirName
    else
      rimraf.sync Environment.conf.target
      fs.mkdirSync Environment.conf.target, 0o777
      wrench.copyDirSyncRecursive Environment.conf.source, Environment.conf.target
    rimraf Environment.conf.target + "/.git", (result) ->
      rimraf Environment.conf.target + "/.gitignore", (result) ->
        rimraf Environment.conf.target + "/_site", (result) ->
          rimraf Environment.conf.target + "/.DS_Store", (result) ->
            rimraf Environment.conf.target + "/restatic.json", (result) ->

Environment::loadConfigFile = (fileName) ->
  unless typeof Environment.conf.source is "undefined"
    contents = fs.readFileSync(Environment.conf.source + fileName)
    config = JSON.parse(contents)
  unless typeof config is "undefined"
    Environment.conf.apiKey = config.apiKey
    Environment.conf.delimiter = config.delimiter
    Environment.conf.extractor = config.extractor

Environment::fixEndingSlash = (path) ->
  unless path.charAt(path.length - 1) is "/"
    path + "/"
  else
    path

Environment::loadLineArgs = (args) ->
  checked = true
  unless args[0] is "-d"
    unless typeof args[0] is "undefined"
      Environment.conf.source = @fixEndingSlash(path.resolve(args[0]))
    else
      checked = false
    unless typeof args[1] is "undefined"
      Environment.conf.target = @fixEndingSlash(path.resolve(args[1]))
    else
      checked = false
    Environment.conf.mode = args[2]  unless typeof args[2] is "undefined"
  else
    Environment.conf.source = "./"
    Environment.conf.target = "./_site/"
    Environment.conf.mode = args[1]
  checked

Environment::storeResult = (data, target) ->
  i = 0
  for key of data
    i++
  length = i
  i = 0
  json = "{"
  for key of data
    json += "\"" + key + "\" : \"" + data[key] + "\""
    json += ", "  unless (i + 1) is length
    i++
  json += "}"
  log = fs.createWriteStream(target + "data.json",
    flags: "w"
  )
  log.end json + "\n"
  cursor.green().write("Data fetched in ").blue().write(target + "data.json").reset().reset().write "\n"

Environment::loadData = (source, target, callback) ->
  callback JSON.parse(fs.readFileSync(target + "data.json").toString()), target

Environment::checkResults = ->
  result = true
  unless typeof Environment.conf.source is "undefined"
    unless path.existsSync(Environment.conf.source)
      cursor.red().write("Source dir doesn't exists.").reset().write "\n"
      result = false
  else
    cursor.red().write("Source dir isn't specified correctly in config file.").reset().write "\n"
    result = false
  unless typeof Environment.conf.target is "undefined"
    fs.mkdirSync Environment.conf.target, 0o777  unless path.existsSync(Environment.conf.target)
  else
    cursor.red().write("Target dir isn't specified correctly in config file.").reset().write "\n"
    result = false
  if typeof Environment.conf.apiKey is "undefined"
    cursor.red().write("API key isn't specified correctly in configfile.").reset().write "\n"
    result = false
  if typeof Environment.conf.delimiter is "undefined"
    cursor.red().write("Delimiter isn't specified correctly in configfile.").reset().write "\n"
    result = false
  result

module.exports = Environment