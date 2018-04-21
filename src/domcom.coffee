module.exports = dc = require('./dc')

if typeof window != 'undefined'
  window.dc = dc

dc.DomNode = require('./DomNode')

dc.extend = extend = require('extend')

dc.EventMixin = require('./dc-event')

extend(dc, dc.flow = require('lazy-flow'))
require('lazy-flow/addon')
dc.bindings = dc.flow.bindings
require('dc-watch-list')

extend(dc,
  require('dc-util'),
  require('./dom-util'),
  require('./dc-render'),

  # components
  require('./core'),

  require('./dc-error')
)

dc.property = require('./core/property')
dc.builtinDirectives = require('./directives/index')
extend(dc,
  dc.property
  dc.builtinDirectives
)



