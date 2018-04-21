extend = require('extend')

exports.newDemoNode = (id) ->
  node = document.createElement('div')
  document.body.appendChild(node)
  id && node.setAttribute('id', id)
  node

exports.fakeEvent = (targetNode, type='click', keyCodeOrOptions) ->
  if typeof keyCodeOrOptions == 'number'
    {
      target:targetNode
      type
      keyCode: keyCodeOrOptions
      preventDefault: ->
      stopPropagation: ->
    }
  else
    extend(
      {
        target: targetNode
        type
        preventDefault: ->
        stopPropagation: ->
      },
      keyCodeOrOptions
    )