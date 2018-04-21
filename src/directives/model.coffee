{getBindProp} = require('../dom-util')

module.exports = (binding, eventName) -> (comp) ->
  {props} = comp
  bindProp = getBindProp(comp)
  comp.setProp(bindProp, binding, props, 'Props')
  comp.bind(eventName || 'onchange', ((event, node) ->
    binding(node[bindProp])),
    'before'
  )
  comp