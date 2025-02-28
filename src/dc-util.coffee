camelCase = require('camelcase')

export default exports = module.exports = {}

exports.normalizeItem = normalizeItem = (item, index) ->
  if typeof item == 'string'
    return item
  else if item instanceof dc.Component
    return item.getReactElement(index)
  else if isArray(item)
    return normalizeArrayViewItem(item)
  else if item?
    return ''+item
  else
    return null

normalizeArrayViewItem = (item) ->
  i = 0
  it = item[i]
  if it instanceof dc.Component || isArray(it)
    tag = 'div'
    props = {}
    children = item.map((child, index) -> normalizeItem(child, index))
    return [tag, props, children]
  else if typeof it== 'string'
    [tag, classes, id, css, inputType] = parseTagString(item[i])
    classes = classname(classes)
    css = styleFrom(css)
    i++
  else if isReactClass(it)
    tag = it
    i++
    it = item[i]
    if typeof it == 'string' && it
      if it.match /^\.|^#/
        [_, classes, id, css, inputType] = parseTagString(item[i])
        classes = classname(classes)
        css = styleFrom(css)
        i++
        it = item[i]
  else if typeof it == 'function'
    x = it(item[1...]...)
    return normalizeItem x
  # props and children
  props = null
  it = item[i]
  while isMap(it)
    props = Object.assign({id}, it)
    tag = tag || it.tag || 'div'
    delete props.tag
    classes = classname(classes, it.classes, it.className)
    delete props.classes
    props.className = classes
    css = styleFrom(css, it.css, it.style)
    delete props.css
    props.style = css
    i++
    it = item[i]
  if !props
    props = {className:classes, id, style:styleFrom(css)}
  if inputType
    props.type = inputType
  children = item[i...].map((child, index) -> normalizeItem(child, index))
  props = normalizeReactProps(props, typeof tag == 'string')
  return [tag || 'div', props, children]

dontCamelCaseReactProps = ['dangerouslySetInnerHTML', 'aria-hidden']
normalizeReactProps = (props, camel = true) ->
  if props.dontCamel
    camel = false
    delete props.dontCamel
  for key of props
    value = props[key]
    if camel
      delete props[key]
      if !dontCamelCaseReactProps.includes(key)
        key = camelCase key
    if value == undefined
      delete props[key]
    else if key == 'className'
      classMap = classname(value)
      if classes = Object.keys(classMap).filter((key) -> classMap[key]).join(' ')
        props.className = classes
      else
        delete props.className
    else if key == 'style'
      if Object.keys(value).length
        props.style = camelCaseStyle value
      else
        delete props.style
    else if camel
      props[key] = value
  props

camelCaseStyle = (style) ->
  result = {}
  for key of style
    value = style[key]
    if !(key.startsWith('MozOsx') || key.startsWith('Webkit'))
      key = camelCase key
    result[key] = value
  result
inputTypes = {}

for type in 'text checkbox radio date email tel number password'.split(' ')
  inputTypes[type] = 1

# tag.class#id##css
parseTagString = (str) ->
  str = str.trim()
  list = str.split('##')
  if list.length == 2
    css = list[1].trim()
    str = list[0].trim()
  list = str.split('#')
  if list.length == 2
    id = list[1].trim()
    str = list[0].trim()
  list = str.split('.')
  if list.length > 1
    tag = list[0]
    classes = classname list.slice(1)
  else
    tag = str
    classes = []
  if inputTypes[tag]
    inputType = tag
    tag = 'input'
  [tag || 'div', classes, id, css, inputType]

styleFrom = (items...) ->
  result = {}
  for item in items
    if typeof item == 'string'
      item = item.trim()
      if !item
        continue
      defs = item.split(/\s*;\s*/)
      for def in defs
        if !def
          continue
        [key, value] = def.split /\s*:\s*/
        if !key || !value
          dc.error 'format error in css rules: empty key'
        else if !value
          dc.error 'format error in css rules: empty value'
        key  = camelCase key
        result[key] = value
    else if isMap item
      Object.assign result, item
  return result

classname = (items...) ->
  classMap = {}
  for item in items
    if !item
      continue
    else if typeof item == 'string'
      names = item.trim().split(/(?:\s*,\s*)|\s+/)
      for name in names
        classMap[name] = 1
    else if isArray item
      for name in item
        classMap[name] = 1
    else if isObject item
      Object.assign(classMap, item)

  return classMap

isReactClass = (item) ->
  # investigated on both CreateClass and ES6 extends react.Component
  item && item.prototype && item.prototype.isReactComponent


exports.watchField = (data, prop, comp) ->
  closure = ->
    value = data[prop]
    Object.defineProperty data, prop, {
      get: -> value
      set:(v) ->
        value = v
        comp.update()
    }
    return
  closure()
  return

exports.watchDataField = (data, prop, comp) ->
  do ->
    value = data[prop]
    Object.defineProperty data, prop, {
      get: -> value
      set:(v) ->
        if v != value
          value = v
          for comp in data.watchingComponents
            comp.update()
        return v
    }
    return
  return

exports.normalizeDomElement = (domElement) ->
  if typeof domElement == 'string'
    domElement = document.querySelector(domElement)
  domElement

exports.isArray = isArray =
isArray = (item) ->
  Object::toString.call(item) == '[object Array]'

exports.isObject = isObject = (item) ->
  typeof item == 'object' and item != null

exports.isMap = isMap = (item) ->
  typeof item == 'object' and item != null && item.constructor == Object

dcid = 0
exports.newDcid = ->
  return 'dcid-' + dcid++